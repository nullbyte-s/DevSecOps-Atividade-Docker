#!/bin/bash

export RDS_PW="HYe^f&ANT-Ed#zn7Ckvl-T"
TEMPLATE_S3_URI="s3://cf-templates--1vw6kw23ktlq-us-east-1/template-1727810020829.yaml"
TEMPLATE_URL="https://cf-templates--1vw6kw23ktlq-us-east-1.s3.amazonaws.com/template-1727810020829.yaml"
TEMPLATE_FILE="template-1727810020829.yaml"
RED_TEXTCOLOR='\033[0;31m'
BOLDCYAN_TEXTCOLOR='\033[1;36m'
NOCOLOR='\033[0m'

sleeping() {
    sleep 1
    clear
}

while true; do
    echo -e "\n${RED_TEXTCOLOR}Atividade Docker - CloudFormation Manager${NOCOLOR}\n"
    echo -e "${BOLDCYAN_TEXTCOLOR}Escolha uma ação:"
    echo "1) Atualizar Template"
    echo "2) Criar Stack"
    echo "3) Verificar Stack"
    echo "4) Deletar Stack"
    echo -e "0) Sair${NOCOLOR}\n"
    
    read -p "Informe o número da ação desejada: " acao
    
    case $acao in
        1)
            echo -e "Atualizando Template...\n"
            if [ ! -f "$TEMPLATE_FILE" ]; then
                echo "Baixando o template do S3..."
                aws s3 cp "$TEMPLATE_URL" "$TEMPLATE_FILE"
            fi
            truncate -s 0 "$TEMPLATE_FILE"
            nano "$TEMPLATE_FILE"
            wait $!
            echo -e "Fazendo upload do template atualizado para o S3...\n"
            if aws s3 cp $TEMPLATE_FILE $TEMPLATE_S3_URI; then
                echo "Template atualizado com sucesso!"
                sleeping
            else
                echo "Erro ao enviar o template para o S3." >&2
                exit 1
            fi
        ;;
        2)
            echo -e "Criando Stack...\n"
            aws cloudformation create-stack \
            --stack-name Atividade-Docker \
            --template-url $TEMPLATE_URL \
            --parameters ParameterKey=RDSMasterPassword,ParameterValue="$RDS_PW" \
            --tags Key=CostCenter,Value=C092000024 Key=Name,Value="PB - JUN 2024" Key=Project,Value="PB - JUN 2024" \
            --capabilities CAPABILITY_IAM
            sleeping
        ;;
        3)
            echo -e "Verificando Stack...\n"
            aws cloudformation describe-stacks --stack-name Atividade-Docker
            sleeping
        ;;
        4)
            echo -e "Deletando Stack...\n"
            aws cloudformation delete-stack --stack-name Atividade-Docker
            sleeping
        ;;
        0)
            echo "Saindo..."
            sleeping
            break
        ;;
        *)
            echo "Opção inválida! Por favor, escolha uma ação válida."
            sleeping
        ;;
    esac
done

: <<'COMMANDS'
# Criar, tornar executável e executar este script
nano Atividade-Docker_Cloud-Shell-Script.sh
sudo chmod +x ./Atividade-Docker_Cloud-Shell-Script.sh
./Atividade-Docker_Cloud-Shell-Script.sh

# Debugging / Testing
find / -name "amazon-efs-utils" -executable -print 2>/dev/null
docker logs -f wordpress
docker exec -it wordpress bash
sudo umount /var/www/html/wp-content
lsof /var/www/html/wp-content
COMMANDS