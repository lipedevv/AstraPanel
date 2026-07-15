<?php

return [
    'sign_in' => 'Entrar',
    'go_to_login' => 'Ir para o login',
    'failed' => 'Nenhuma conta corresponde às credenciais informadas.',
    'forgot_password' => [
        'label' => 'Esqueceu a senha?',
        'label_help' => 'Informe o e-mail da sua conta para receber as instruções de redefinição.',
        'button' => 'Recuperar conta',
    ],
    'reset_password' => ['button' => 'Redefinir e entrar'],
    'two_factor' => [
        'label' => 'Código de dois fatores',
        'label_help' => 'Esta conta exige uma segunda etapa de autenticação. Informe o código gerado pelo seu dispositivo.',
        'checkpoint_failed' => 'O código de autenticação de dois fatores é inválido.',
    ],
    'throttle' => 'Muitas tentativas de login. Tente novamente em :seconds segundos.',
    'password_requirements' => 'A senha deve ter pelo menos 8 caracteres e ser exclusiva para este site.',
    '2fa_must_be_enabled' => 'O administrador exige que a autenticação de dois fatores esteja habilitada para usar o painel.',
];
