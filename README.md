<h1 align="center">Infraestrutura AWS com Docker</h1>

![topologia](https://github.com/user-attachments/assets/e8c65ae4-2ae1-4cea-9a86-dbe34acdf10b)

O presente repositório se refere a uma atividade que exige o cumprimento das seguintes tarefas:

        1. Instalação e configuração do Docker no host EC2 (podendo utilizar a instalação via script de Start Instance - user_data.sh);
        2. Efetuar Deploy de uma aplicação Wordpress com: container de aplicação RDS database Mysql;
        3. Configuração da utilização do serviço EFS AWS para estáticos do container de aplicação Wordpress;
        4. Configuração do serviço de Load Balancer AWS para a aplicação Wordpress.

    𝙿𝚘𝚗𝚝𝚘𝚜 𝚍𝚎 𝙰𝚝𝚎𝚗çã𝚘:
    
        • Não utilizar IP público para saída do serviços do Wordpress (evitar a publicação do serviço WP via IP Público);
        • Sugestão: o tráfego de internet pode sair pelo Load Balancer Classic;
        • Para pastas públicas e estáticos do wordpress, utilizar o EFS (Elastic File System);
        • Utilizar o Dockerfile ou Dockercompose;
        • A aplicação Wordpress precisa estar rodando na porta 80 ou 8080.

## Sumário
1. [Descrição](#descrição)
2. [Arquitetura](#arquitetura)
3. [Configuração e Implantação](#configuração-e-implantação)
4. [Acesso à Aplicação](#acesso-à-aplicação)
5. [Encerramento da Infraestrutura](#encerramento-da-infraestrutura)
6. [Considerações de Segurança](#considerações-de-segurança)
7. [Acesso às Instâncias EC2 via Session Manager](#acesso-às-instâncias-ec2-via-session-manager)
8. [Troubleshooting](#troubleshooting)


## Descrição

Este projeto implementa uma infraestrutura AWS para hospedar uma aplicação WordPress utilizando Docker, com foco em alta disponibilidade, segurança e escalabilidade. A infraestrutura, criada usando AWS CloudFormation, inclui serviços como EC2, RDS, EFS e Load Balancer, sendo implantada em duas zonas de disponibilidade (us-east-1a e us-east-1b). Para simplificar o gerenciamento da stack, foi criado um script Bash, que facilita a administração via Cloud Shell. Foram aplicadas tags comuns a todos os recursos, além de tags específicas, para uma identificação clara e a compreensão das associações entre eles. O esqueleto inicial do template foi elaborado através do "Application Composer", que facilita a montagem visual e permite a edição direta das propriedades do template, além de proporcionar sua validação básica.


## Arquitetura

A arquitetura da solução é composta por:

* **Rede:** VPC com sub-redes públicas e privadas em duas zonas de disponibilidade. Um NAT Gateway permite que as instâncias EC2 nas sub-redes privadas acessem a internet sem serem expostas publicamente.
* **Instâncias EC2:**  Utiliza Auto Scaling para manter a disponibilidade e escalabilidade das instâncias. As instâncias EC2 executam o WordPress em contêineres Docker e montam o sistema de arquivos EFS para persistência de dados.
* **Banco de Dados RDS (MySQL):** Hospeda o banco de dados do WordPress.
* **Sistema de Arquivos EFS:** Armazena o conteúdo do WordPress, permitindo que as instâncias EC2 acessem os mesmos dados.
* **Load Balancer:** Distribui o tráfego entre as instâncias EC2 em execução.
* **Segurança:** Grupos de segurança controlam o tráfego de entrada e saída para as instâncias EC2, RDS e EFS.
* **Automação:** Funções Lambda e regras de agendamento (CloudWatch Events) iniciam e param as instâncias EC2, RDS e NAT Gateway em horários específicos, otimizando custos. Essa funcionalidade não foi finalizada, se fazendo necessário ajustes no código para operar conforme o pretendido.


## Configuração e Implantação

1. **CloudFormation Template:** O arquivo `CloudFormation-Template.yaml` define a infraestrutura. Ele cria todos os recursos necessários, incluindo VPC, subnets, instâncias EC2, RDS, EFS, Load Balancer e grupos de segurança. Esse template foi devidamente comentado para facilitar a compreensão de cada recurso a ser implantado.

2. **Script de Gerenciamento:** O script `Atividade-Docker_Cloud-Shell-Script.sh` facilita o gerenciamento da stack do CloudFormation. Ele permite:
    * Atualizar o template do CloudFormation.
    * Criar a stack.
    * Verificar o status da stack.
    * Deletar a stack.

3. **Configuração do Script:**
    * A variável `RDS_PW` no script deve corresponder à senha definida no parâmetro `RDSMasterPassword` do template (ou o valor padrão no template deve ser alterado).
    * A variável `TEMPLATE_S3_URI` deve apontar para um bucket S3 onde o template será armazenado.
    * A variável `TEMPLATE_URL` deve ser a URL pública do template no S3.

4. **Execução do Script:**
    * O script `Atividade-Docker_Cloud-Shell-Script.sh` deve estar no Cloud Shell.
    * Comando para torná-lo executável: `chmod +x Atividade-Docker_Cloud-Shell-Script.sh`.
    * Executar o script: `./Atividade-Docker_Cloud-Shell-Script.sh`.
    * Após a execução, um menu de instruções orientará as possibilidades de criar ou gerenciar a stack.


## Acesso à Aplicação

Após a criação da stack, o WordPress estará acessível através do DNS do Load Balancer, que pode ser obtido na saída da stack do CloudFormation. Ao acessá-lo, deve-se completar a configuração inicial do WordPress.


## Encerramento da Infraestrutura

Executar a opção 4 no script `Atividade-Docker_Cloud-Shell-Script.sh` deletará a stack do CloudFormation, removendo todos os recursos criados pelo template.


## Considerações de Segurança

* As regras de segurança foram configuradas para restringir o acesso aos recursos.
* A senha do RDS é armazenada como um parâmetro do CloudFormation com a opção `NoEcho` habilitada para segurança.
* Durante o desenvolvimento do template, foi usado o acesso via SSH. O trecho relevante está comentado no template, bastando remover o comentário das linhas de SSH no grupo de segurança `EC2SecurityGroup`, para fins de testes. Numa segunda etapa, visando as boas práticas para um ambiente de produção, foi utilizado um método mais seguro, o Session Manager, a seguir descrito.


## Acesso às Instâncias EC2 via Session Manager

O template configura as instâncias EC2 para acesso via AWS Systems Manager Session Manager (SSM Session Manager), permitindo conexões seguras sem a necessidade de gerenciar chaves SSH ou abrir a porta 22. Nesse serviço, o acesso é controlado por meio de políticas IAM, permitindo um controle preciso sobre quem pode acessar as instâncias. Além disso, as sessões são registradas, fornecendo um histórico de todas as atividades realizadas nas instâncias. Para habilitar o acesso através do Session Manager, a política `AmazonSSMManagedInstanceCore` foi anexada à role da instância EC2 (`EC2InstanceRole`), concedendo as permissões necessárias para o SSM Agent funcionar.

**Utilizando o SSM Session Manager:**

1. **Instalação do SSM Agent:** O `UserData` das instâncias EC2 já inclui a instalação e configuração do SSM Agent.
2. **Conexão:** Após a criação da stack, navegar até o serviço Systems Manager no console da AWS, selecionar "Session Manager" e escolher a instância EC2 que se deseja acessar.
3. **Execução de comandos:** Uma vez conectado, pode-se executar comandos no terminal da instância EC2 como se estivesse conectado via SSH.


## Troubleshooting

* Verificar os logs do CloudFormation permite identificar erros durante a criação da stack.
* O comando `docker logs -f wordpress` dentro das instâncias EC2 permite verificar os logs do container WordPress.
* Outros comandos relavantes usados durante os testes estão comentados ao final do script Bash.

---

<h5 align="center">Made with 💜 by <a href="https://github.com/nullbyte-s/">nullbyte-s</a><br>