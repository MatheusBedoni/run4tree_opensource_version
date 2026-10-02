# Run4Tree 🌲🏃‍♂️

**Run4Tree: um app de corrida que planta árvores reais.**

O Run4Tree é um aplicativo sustentável e gamificado onde sua atividade física e seus quilômetros corridos se transformam em impacto ecológico real, ajudando no reflorestamento.

## 🚀 Atualizações Recentes e Ajustes
- **Arquitetura (Clean Architecture):** O projeto foi estruturado seguindo os princípios de Clean Architecture para facilitar a escalabilidade e manutenção. Os diretórios já foram separados em `domain`, `data` e `presentation` (na feature de autenticação).
- **Nova Tela de Login:** Interface moderna e atrativa (premium) implementada.
- **Tematização Sustentável:** Adoção de uma paleta de cores verde (`#4CAF50` e `#006E1C`), combinada com a tipografia **Poppins** (`google_fonts`), para reforçar a temática da natureza e sustentabilidade.
- **Widgets de Impacto:** Implementação inicial da barra de progresso visual de impacto, que exibe o número total de árvores plantadas pela comunidade de corredores.
- **Integração Tree-Nation:** Preparação da arquitetura base para o plantio de árvores reais conectando com a API da Tree-Nation, incluindo o pacote HTTP (`dio`), gerenciamento de Token via `.env` e serviço dedicado (`TreeNationService`).
- **Persistência Local (Offline):** Implementação de banco de dados local com `sqflite` para salvar o histórico de exercícios do usuário e permitir o funcionamento offline do app.
- **Modelagem de Dados Estruturada:** Uso do `json_serializable` para garantir que modelos de usuários, exercícios e estatísticas de corrida sejam parseados de forma segura e confiável.
## 🛠️ Tecnologias Utilizadas
- [Flutter](https://flutter.dev/)
- [Google Fonts](https://pub.dev/packages/google_fonts)
- [Font Awesome Flutter](https://pub.dev/packages/font_awesome_flutter)
- [Dio (HTTP Client)](https://pub.dev/packages/dio)
- [Flutter Dotenv](https://pub.dev/packages/flutter_dotenv)
- [Json Serializable / Annotation](https://pub.dev/packages/json_serializable)
- [Sqflite (Local Database)](https://pub.dev/packages/sqflite)
## 🏃 Como Rodar o Projeto

1. Certifique-se de ter o ambiente Flutter configurado.
2. Acesse a pasta do projeto e baixe as dependências:
   ```bash
   flutter pub get
   ```
3. Crie o arquivo `.env` na raiz do projeto (use o `.env.example` como base) e preencha as variáveis de ambiente, incluindo a chave da API da Tree-Nation:
   ```bash
   cp .env.example .env
   ```
4. Rode o aplicativo:
   ```bash
   flutter run
   ```
