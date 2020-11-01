#! /bin/bash
sudo apt --yes install unzip
wget https://releases.hashicorp.com/terraform/0.13.5/terraform_0.13.5_linux_amd64.zip -O terraform.zip
sudo unzip terraform.zip
sudo mv terraform /usr/local/bin/
rm terraform.zip
wget https://vstsagentpackage.azureedge.net/agent/2.175.2/vsts-agent-linux-x64-2.175.2.tar.gz -O vstsagent.tar.gz
mkdir vstsagent
mv vstsagent.tar.gz vstsagent
cd vstsagent
tar -zxvf vstsagent.tar.gz
rm vstsagent.tar.gz
./config.sh --unattended --url <url> --auth pat --token <token> --pool 'Terraform' --agent 'Terraform 01' --replace --work /home/vsts/work --acceptTeeEula
sudo ./svc.sh install
sudo ./svc.sh start
