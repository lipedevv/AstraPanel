<?php

use Pterodactyl\Models\Node;
use Pterodactyl\Models\Location;
use Symfony\Component\Yaml\Yaml;
use Pterodactyl\Services\Nodes\NodeCreationService;
use Pterodactyl\Services\Allocations\AssignmentService;
use Pterodactyl\Repositories\Wings\DaemonConfigurationRepository;

require '/app/vendor/autoload.php';

$app = require '/app/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

function requiredEnvironment(string $name): string
{
    $value = getenv($name);
    if ($value === false || $value === '') {
        throw new RuntimeException(sprintf('Missing required environment variable: %s', $name));
    }

    return $value;
}

$action = getenv('NODE_ACTION') ?: 'provision';
if ($action === 'check') {
    $node = Node::query()->findOrFail((int) requiredEnvironment('NODE_ID'));
    $information = app(DaemonConfigurationRepository::class)->setNode($node)->getSystemInformation();
    echo $information['version'] ?? 'connected';

    return;
}

$nodeName = requiredEnvironment('NODE_NAME');
$nodeFqdn = requiredEnvironment('NODE_FQDN');
$panelPublicUrl = rtrim(requiredEnvironment('PANEL_PUBLIC_URL'), '/');
$stateDirectory = rtrim(requiredEnvironment('WINGS_STATE_DIR'), '/');
$memory = (int) requiredEnvironment('NODE_MEMORY_MB');
$disk = (int) requiredEnvironment('NODE_DISK_MB');
$allocationIp = requiredEnvironment('ALLOCATION_IP');
$allocationPorts = array_values(array_filter(explode(',', requiredEnvironment('ALLOCATION_PORTS'))));
$dockerNetworkName = requiredEnvironment('WINGS_NETWORK_NAME');
$dockerNetworkSubnet = requiredEnvironment('WINGS_NETWORK_SUBNET');
$dockerNetworkGateway = requiredEnvironment('WINGS_NETWORK_GATEWAY');

if (!preg_match('/^[a-z0-9.-]+$/i', $nodeFqdn)) {
    throw new RuntimeException('NODE_FQDN contains invalid characters.');
}
if (filter_var($panelPublicUrl, FILTER_VALIDATE_URL) === false) {
    throw new RuntimeException('PANEL_PUBLIC_URL must be a valid URL.');
}
if (!preg_match('#^/[A-Za-z0-9._/-]+$#', $stateDirectory)) {
    throw new RuntimeException('WINGS_STATE_DIR must be a safe absolute path.');
}
if ($memory < 1024 || $disk < 2048) {
    throw new RuntimeException('The node requires at least 1024 MB of memory and 2048 MB of disk.');
}
if (filter_var($allocationIp, FILTER_VALIDATE_IP, FILTER_FLAG_IPV4) === false) {
    throw new RuntimeException('ALLOCATION_IP must be a valid IPv4 address.');
}
if (!preg_match('/^[a-zA-Z0-9_.-]+$/', $dockerNetworkName)) {
    throw new RuntimeException('WINGS_NETWORK_NAME contains invalid characters.');
}
if (!preg_match('#^(?:\d{1,3}\.){3}\d{1,3}/\d{1,2}$#', $dockerNetworkSubnet)) {
    throw new RuntimeException('WINGS_NETWORK_SUBNET must be a valid IPv4 CIDR range.');
}
if (filter_var($dockerNetworkGateway, FILTER_VALIDATE_IP, FILTER_FLAG_IPV4) === false) {
    throw new RuntimeException('WINGS_NETWORK_GATEWAY must be a valid IPv4 address.');
}

$location = Location::query()->firstOrCreate(
    ['short' => 'codespace'],
    ['long' => 'GitHub Codespaces']
);

$nodeData = [
    'public' => true,
    'name' => $nodeName,
    'description' => 'Automatically managed GitHub Codespaces node.',
    'location_id' => $location->id,
    'fqdn' => $nodeFqdn,
    'scheme' => 'https',
    'behind_proxy' => true,
    'maintenance_mode' => false,
    'memory' => $memory,
    'memory_overallocate' => 0,
    'disk' => $disk,
    'disk_overallocate' => 0,
    'upload_size' => 100,
    'daemonBase' => $stateDirectory . '/volumes',
    'daemonSFTP' => 2022,
    'daemonListen' => 443,
];

$node = Node::query()->where('name', $nodeName)->first();
if ($node === null) {
    $node = app(NodeCreationService::class)->handle($nodeData);
} else {
    $node->fill($nodeData);
    $node->save();
    $node->refresh();
}

app(AssignmentService::class)->handle($node, [
    'allocation_ip' => $allocationIp,
    'allocation_alias' => null,
    'allocation_ports' => $allocationPorts,
]);

$configuration = $node->getConfiguration();
$configuration['remote'] = 'http://panel';
$configuration['allowed_origins'] = [$panelPublicUrl];
$configuration['ignore_panel_config_updates'] = true;
$configuration['system']['root_directory'] = $stateDirectory;
$configuration['system']['log_directory'] = $stateDirectory . '/logs';
$configuration['system']['archive_directory'] = $stateDirectory . '/archives';
$configuration['system']['backup_directory'] = $stateDirectory . '/backups';
$configuration['system']['tmp_directory'] = $stateDirectory . '/tmp';
$configuration['api']['host'] = '0.0.0.0';
$configuration['api']['port'] = 8080;
$configuration['api']['ssl']['enabled'] = false;
$configuration['docker']['network'] = [
    'interface' => $dockerNetworkGateway,
    'name' => $dockerNetworkName,
    'network_mode' => $dockerNetworkName,
    'interfaces' => [
        'v4' => [
            'subnet' => $dockerNetworkSubnet,
            'gateway' => $dockerNetworkGateway,
        ],
    ],
];

$temporaryConfiguration = '/tmp/astra-panel-codespaces-wings.yml';
file_put_contents(
    $temporaryConfiguration,
    Yaml::dump($configuration, 8, 2, Yaml::DUMP_EMPTY_ARRAY_AS_SEQUENCE)
);

echo $node->id;
