provider "aws" {
  region     = var.AWS_REGION
  access_key = var.AWS_ACCESS_KEY
  secret_key = var.AWS_SECRET_KEY
}
resource "aws_security_group" "instance_sg" {
  name = "terraform-test-sg"
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_key_pair" "my_ec2" {
  key_name   = "terraform-key"
  public_key = file(var.ssh_key)
}
resource "aws_instance" "my_ec2_instance" {
  key_name               = aws_key_pair.my_ec2.key_name
  ami                    = var.AWS_AMIS
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.instance_sg.id]
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file(var.private_key)
    host        = self.public_ip
  }
  provisioner "file" {
    source      = "./demoterraformdeploytoec2-0.0.1-SNAPSHOT.jar"
    destination = "/tmp/demoterraformdeploytoec2-0.0.1-SNAPSHOT.jar"
  }
  provisioner "remote-exec" {
    inline = [
      # Installe le JDK 17
      "sudo apt-get update",
      "sudo apt-get install -y openjdk-17-jdk",
      "sudo update-alternatives --set java /usr/lib/jvm/java-17-openjdk-amd64/bin/java",

      # Déplace le fichier jar dans le dossier home de l'utilisateur
      "cp /tmp/demoterraformdeploytoec2-0.0.1-SNAPSHOT.jar ~/",
      #C:\Users\talla\IdeaProjects\demoterraformdeploytoec2 \IdeaProjects

      # Démarre l'application avec Java
      "nohup java -jar ~/demoterraformdeploytoec2-0.0.1-SNAPSHOT.jar --server.port=8081 > ~/my-application.log 2>&1 &",
    ]
  }
}