# Lista de Tarefas - Correção Projeto Flutter FederacaoMAD

- [X] 1. Analisar erros de build e execução do projeto (CodeMagic logs e descrição do usuário).
- [X] 2. Corrigir erros de sintaxe e estruturais no código Flutter (main.dart, register_screen.dart, etc.).
- [X] 3. Gerar o arquivo `firebase_options.dart` ausente.
- [X] 4. Revisar e reconfigurar a integração com Firebase (verificar dependências, inicialização, SDKs necessários: Auth, Firestore, Storage, Remote Config).
- [X] 5. Implementar ajustes para autenticação e fluxo de login (corrigir problema do "círculo girando", garantir navegação para home).
- [X] 6. Garantir funcionamento do som inicial (verificar splash_screen.dart ou main.dart).
- [X] 7. Validar estrutura e acesso às funcionalidades da home screen (VoIP, chat, clãs, federações, imagens, config, canais de voz, registro de membros) - *Observação: UI da lista de chat (`ChatListTab`) precisa ser implementada.*
- [X] 8. Atualizar dependências do Flutter para versões estáveis mais recentes (manualmente).
- [ ] 9. Gerar arquivo ZIP final com o projeto corrigido.
- [ ] 10. Enviar o arquivo ZIP para o usuário.


## Fase 5: Atualização de Assets (Conforme Solicitação Adicional)

- [X] **Remover Assets Antigos:** Removidos arquivos JPG e PNG desnecessários da pasta `assets/images_png/`.
- [X] **Converter e Adicionar Novos Assets:**
    - [X] Convertida imagem JPG (`1001023861.jpg`) para PNG.
    - [X] Adicionada nova logo (`app_logo.png`).
    - [X] Adicionado novo fundo de carregamento (`loading_background.png`).
    - [X] Adicionadas imagens de clã (`clan_images/clan_image_01.png`, `clan_images/clan_image_02.png`).
- [X] **Atualizar Referências:**
    - [X] Atualizado `pubspec.yaml` para usar `app_logo.png` como ícone.
    - [X] Atualizado `splash_screen.dart` para usar `app_logo.png` e `loading_background.png`.
    - [ ] Verificar outras referências de assets no código (A fazer: pelo usuário durante testes/refinamentos).

