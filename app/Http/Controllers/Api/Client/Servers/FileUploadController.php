<?php

namespace Pterodactyl\Http\Controllers\Api\Client\Servers;

use Carbon\CarbonImmutable;
use GuzzleHttp\Client;
use GuzzleHttp\Exception\BadResponseException;
use Pterodactyl\Models\User;
use Pterodactyl\Enum\JwtScope;
use Pterodactyl\Models\Server;
use Illuminate\Http\JsonResponse;
use Illuminate\Validation\ValidationException;
use Symfony\Component\HttpKernel\Exception\BadRequestHttpException;
use Pterodactyl\Services\Nodes\NodeJWTService;
use Pterodactyl\Http\Controllers\Api\Client\ClientApiController;
use Pterodactyl\Http\Requests\Api\Client\Servers\Files\UploadFileRequest;

class FileUploadController extends ClientApiController
{
    private const MAX_CODESPACES_CHUNK_SIZE = 12 * 1024 * 1024;

    /**
     * FileUploadController constructor.
     */
    public function __construct(
        private NodeJWTService $jwtService,
    ) {
        parent::__construct();
    }

    /**
     * Returns an url where files can be uploaded to.
     */
    public function __invoke(UploadFileRequest $request, Server $server): JsonResponse
    {
        return new JsonResponse([
            'object' => 'signed_url',
            'attributes' => [
                'url' => $this->getUploadUrl($server, $request->user()),
            ],
        ]);
    }

    /**
     * Receives a file in chunks that fit through the Codespaces web tunnel,
     * assembles it locally, and streams the completed file directly to Wings.
     */
    public function chunk(UploadFileRequest $request, Server $server): JsonResponse
    {
        $data = $request->validate([
            'upload_id' => ['required', 'string', 'regex:/^[A-Za-z0-9-]{16,100}$/'],
            'chunk_index' => ['required', 'integer', 'min:0'],
            'chunks_total' => ['required', 'integer', 'min:1', 'max:2048'],
            'file_name' => ['required', 'string', 'max:255'],
            'directory' => ['required', 'string', 'max:4096'],
            'chunk' => ['required', 'file', 'max:' . intdiv(self::MAX_CODESPACES_CHUNK_SIZE, 1024)],
        ]);

        $fileName = $data['file_name'];
        $directory = $data['directory'];
        if (str_contains($fileName, '/') || str_contains($fileName, '\\') || str_contains($fileName, "\0")) {
            throw ValidationException::withMessages(['file_name' => 'The file name contains invalid characters.']);
        }
        if (!str_starts_with($directory, '/') || str_contains($directory, "\0")) {
            throw ValidationException::withMessages(['directory' => 'The directory must be an absolute server path.']);
        }

        $root = storage_path(sprintf('app/astra-chunked-uploads/%d/%s', $request->user()->id, $server->uuid));
        if (!is_dir($root) && !mkdir($root, 0700, true) && !is_dir($root)) {
            throw new \RuntimeException('Could not create the temporary upload directory.');
        }
        $this->removeStaleUploads($root);

        $base = $root . DIRECTORY_SEPARATOR . $data['upload_id'];
        $partPath = $base . '.part';
        $metadataPath = $base . '.json';
        $index = (int) $data['chunk_index'];
        $total = (int) $data['chunks_total'];
        $maximumSize = $server->node->upload_size * 1024 * 1024;

        if ($index === 0) {
            @unlink($partPath);
            @unlink($metadataPath);
            $metadata = [
                'file_name' => $fileName,
                'directory' => $directory,
                'chunks_total' => $total,
                'next_chunk' => 0,
                'created_at' => time(),
            ];
        } else {
            $metadata = is_file($metadataPath) ? json_decode((string) file_get_contents($metadataPath), true) : null;
            if (!is_array($metadata)) {
                throw ValidationException::withMessages(['upload_id' => 'The upload session has expired.']);
            }
        }

        if (
            $metadata['file_name'] !== $fileName
            || $metadata['directory'] !== $directory
            || (int) $metadata['chunks_total'] !== $total
            || (int) $metadata['next_chunk'] !== $index
        ) {
            throw ValidationException::withMessages(['chunk_index' => 'The file chunks were received out of order.']);
        }

        $input = fopen($request->file('chunk')->getRealPath(), 'rb');
        $output = fopen($partPath, 'ab');
        if ($input === false || $output === false) {
            throw new \RuntimeException('Could not open the temporary upload file.');
        }
        try {
            if (!flock($output, LOCK_EX) || stream_copy_to_stream($input, $output) === false) {
                throw new \RuntimeException('Could not store the uploaded file chunk.');
            }
            fflush($output);
            flock($output, LOCK_UN);
        } finally {
            fclose($input);
            fclose($output);
        }

        if (filesize($partPath) > $maximumSize) {
            $this->deleteUpload($partPath, $metadataPath);
            throw ValidationException::withMessages([
                'chunk' => sprintf('The file is larger than the node upload limit of %d MB.', $server->node->upload_size),
            ]);
        }

        $metadata['next_chunk'] = $index + 1;
        file_put_contents($metadataPath, json_encode($metadata, JSON_THROW_ON_ERROR), LOCK_EX);

        if ($metadata['next_chunk'] < $total) {
            return new JsonResponse(['completed' => false, 'next_chunk' => $metadata['next_chunk']]);
        }

        try {
            $this->sendCompletedUpload($server, $request->user(), $partPath, $fileName, $directory);
        } finally {
            $this->deleteUpload($partPath, $metadataPath);
        }

        return new JsonResponse(['completed' => true]);
    }

    /**
     * Returns an url where files can be uploaded to.
     */
    protected function getUploadUrl(Server $server, User $user): string
    {
        $token = $this->getUploadToken($server, $user);

        return sprintf(
            '%s/upload/file?token=%s',
            $server->node->getConnectionAddress(),
            $token
        );
    }

    protected function getUploadToken(Server $server, User $user): string
    {
        return $this->jwtService
            ->setExpiresAt(CarbonImmutable::now()->addMinutes(15))
            ->setUser($user)
            ->setClaims(['server_uuid' => $server->uuid])
            ->setScopes(JwtScope::FileUpload)
            ->handle($server->node, $user->id . $server->uuid)
            ->toString();
    }

    protected function sendCompletedUpload(Server $server, User $user, string $path, string $fileName, string $directory): void
    {
        $stream = fopen($path, 'rb');
        if ($stream === false) {
            throw new \RuntimeException('Could not read the assembled upload.');
        }

        try {
            (new Client())->post('http://wings:8080/upload/file', [
                'query' => ['token' => $this->getUploadToken($server, $user), 'directory' => $directory],
                'multipart' => [['name' => 'files', 'contents' => $stream, 'filename' => $fileName]],
                'connect_timeout' => 10,
                'timeout' => 0,
            ]);
        } catch (BadResponseException $exception) {
            $body = (string) $exception->getResponse()->getBody();
            $decoded = json_decode($body, true);
            throw new BadRequestHttpException(
                is_array($decoded) && isset($decoded['error']) ? $decoded['error'] : 'Wings rejected the assembled upload.',
                $exception
            );
        } finally {
            fclose($stream);
        }
    }

    protected function deleteUpload(string $partPath, string $metadataPath): void
    {
        @unlink($partPath);
        @unlink($metadataPath);
    }

    protected function removeStaleUploads(string $root): void
    {
        foreach (glob($root . DIRECTORY_SEPARATOR . '*.{part,json}', GLOB_BRACE) ?: [] as $path) {
            if (is_file($path) && filemtime($path) < time() - 86400) {
                @unlink($path);
            }
        }
    }
}
