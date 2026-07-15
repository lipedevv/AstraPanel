<?php

return [
    'daemon_connection_failed' => 'Ocorreu uma falha ao comunicar com o daemon, resultando no código HTTP/:code. O erro foi registrado.',
    'node' => ['servers_attached' => 'Um node não pode ter servidores vinculados para ser excluído.', 'daemon_off_config_updated' => 'A configuração do daemon foi atualizada, mas o arquivo não pôde ser alterado automaticamente. Atualize o config.yml manualmente.'],
    'allocations' => ['server_using' => 'Um servidor está usando esta allocation.', 'too_many_ports' => 'Não é possível adicionar mais de 1000 portas de uma só vez.', 'invalid_mapping' => 'O mapeamento da porta :port é inválido.', 'cidr_out_of_range' => 'A notação CIDR aceita máscaras entre /25 e /32.', 'port_out_of_range' => 'As portas devem ser maiores que 1024 e menores ou iguais a 65535.'],
    'nest' => [
        'delete_has_servers' => 'Um Nest com servidores ativos não pode ser excluído.',
        'egg' => ['delete_has_servers' => 'Um Egg com servidores ativos não pode ser excluído.', 'invalid_copy_id' => 'O Egg selecionado para copiar o script não existe ou também copia outro script.', 'must_be_child' => 'A origem de configurações deste Egg deve pertencer ao Nest selecionado.', 'has_children' => 'Este Egg possui Eggs filhos. Exclua-os primeiro.'],
        'variables' => ['env_not_unique' => 'A variável de ambiente :name deve ser única neste Egg.', 'reserved_name' => 'A variável :name é protegida.', 'bad_validation_rule' => 'A regra de validação ":rule" não é válida.'],
        'importer' => ['json_error' => 'Erro ao interpretar o arquivo JSON: :error.', 'file_error' => 'O arquivo JSON informado não é válido.', 'invalid_json_provided' => 'O arquivo JSON não está em um formato reconhecido.'],
    ],
    'subusers' => ['editing_self' => 'Não é permitido editar sua própria conta de subusuário.', 'user_is_owner' => 'O proprietário não pode ser adicionado como subusuário.', 'subuser_exists' => 'Um usuário com esse e-mail já é subusuário deste servidor.'],
    'databases' => ['delete_has_databases' => 'Não é possível excluir um host com bancos de dados ativos.'],
    'tasks' => ['chain_interval_too_long' => 'O intervalo máximo de uma tarefa encadeada é 15 minutos.'],
    'locations' => ['has_nodes' => 'Não é possível excluir uma localização com nodes ativos.'],
    'users' => ['node_revocation_failed' => 'Falha ao revogar as chaves no <a href=":link">Node #:node</a>. :error'],
    'deployment' => ['no_viable_nodes' => 'Nenhum node atende aos requisitos da implantação automática.', 'no_viable_allocations' => 'Nenhuma allocation atende aos requisitos da implantação automática.'],
    'api' => ['resource_not_found' => 'O recurso solicitado não existe neste servidor.'],
];
