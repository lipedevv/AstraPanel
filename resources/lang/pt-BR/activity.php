<?php

return [
    'auth' => ['fail' => 'Falha ao entrar', 'success' => 'Entrou na conta', 'password-reset' => 'Redefiniu a senha', 'reset-password' => 'Solicitou redefinição de senha', 'checkpoint' => 'Autenticação de dois fatores solicitada', 'recovery-token' => 'Usou um código de recuperação', 'token' => 'Concluiu o desafio de dois fatores', 'ip-blocked' => 'Bloqueou uma solicitação de IP não autorizado para :identifier', 'sftp' => ['fail' => 'Falha ao entrar por SFTP']],
    'user' => [
        'user' => ['create' => 'Criou o usuário :email'],
        'account' => ['email-changed' => 'Alterou o e-mail de :old para :new', 'password-changed' => 'Alterou a senha'],
        'api-key' => ['create' => 'Criou a chave de API :identifier', 'delete' => 'Excluiu a chave de API :identifier'],
        'ssh-key' => ['create' => 'Adicionou a chave SSH :fingerprint', 'delete' => 'Removeu a chave SSH :fingerprint'],
        'two-factor' => ['create' => 'Ativou a autenticação de dois fatores', 'delete' => 'Desativou a autenticação de dois fatores'],
    ],
    'server' => [
        'reinstall' => 'Reinstalou o servidor', 'console' => ['command' => 'Executou ":command" no servidor'],
        'power' => ['start' => 'Iniciou o servidor', 'stop' => 'Parou o servidor', 'restart' => 'Reiniciou o servidor', 'kill' => 'Encerrou forçadamente o processo do servidor'],
        'backup' => ['download' => 'Baixou o backup :name', 'delete' => 'Excluiu o backup :name', 'restore' => 'Restaurou o backup :name (arquivos excluídos: :truncate)', 'restore-complete' => 'Concluiu a restauração do backup :name', 'restore-failed' => 'Falha ao restaurar o backup :name', 'start' => 'Iniciou o backup :name', 'complete' => 'Marcou o backup :name como concluído', 'fail' => 'Marcou o backup :name como falho', 'lock' => 'Bloqueou o backup :name', 'unlock' => 'Desbloqueou o backup :name'],
        'database' => ['create' => 'Criou o banco de dados :name', 'rotate-password' => 'Alterou a senha do banco :name', 'delete' => 'Excluiu o banco :name'],
        'file' => ['compress_one' => 'Compactou :directory:files.0', 'compress_other' => 'Compactou :count arquivos em :directory', 'read' => 'Visualizou :file', 'copy' => 'Criou uma cópia de :file', 'create-directory' => 'Criou a pasta :directory:name', 'decompress' => 'Descompactou :files em :directory', 'delete_one' => 'Excluiu :directory:files.0', 'delete_other' => 'Excluiu :count arquivos em :directory', 'download' => 'Baixou :file', 'pull' => 'Baixou :url para :directory', 'rename_one' => 'Renomeou :directory:files.0.from para :directory:files.0.to', 'rename_other' => 'Renomeou :count arquivos em :directory', 'write' => 'Alterou o conteúdo de :file', 'upload' => 'Iniciou o envio de um arquivo', 'uploaded' => 'Enviou :directory:file'],
        'sftp' => ['denied' => 'Bloqueou o acesso SFTP por falta de permissão', 'create_one' => 'Criou :files.0', 'create_other' => 'Criou :count arquivos', 'write_one' => 'Alterou :files.0', 'write_other' => 'Alterou :count arquivos', 'delete_one' => 'Excluiu :files.0', 'delete_other' => 'Excluiu :count arquivos', 'create-directory_one' => 'Criou a pasta :files.0', 'create-directory_other' => 'Criou :count pastas', 'rename_one' => 'Renomeou :files.0.from para :files.0.to', 'rename_other' => 'Renomeou ou moveu :count arquivos'],
        'allocation' => ['create' => 'Adicionou :allocation', 'notes' => 'Alterou as notas de :allocation de ":old" para ":new"', 'primary' => 'Definiu :allocation como principal', 'delete' => 'Excluiu :allocation'],
        'schedule' => ['create' => 'Criou o agendamento :name', 'update' => 'Atualizou o agendamento :name', 'execute' => 'Executou manualmente o agendamento :name', 'delete' => 'Excluiu o agendamento :name'],
        'task' => ['create' => 'Criou a tarefa ":action" no agendamento :name', 'update' => 'Atualizou a tarefa ":action" no agendamento :name', 'delete' => 'Excluiu uma tarefa do agendamento :name'],
        'settings' => ['rename' => 'Renomeou o servidor de :old para :new', 'description' => 'Alterou a descrição de :old para :new'],
        'startup' => ['edit' => 'Alterou a variável :variable de ":old" para ":new"', 'image' => 'Alterou a imagem Docker de :old para :new'],
        'subuser' => ['create' => 'Adicionou :email como subusuário', 'update' => 'Atualizou as permissões de :email', 'delete' => 'Removeu :email dos subusuários'],
    ],
];
