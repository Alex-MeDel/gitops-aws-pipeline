resource "aws_security_group" "the_sg" {
    name   = "the-sg"
    description = "Security rules"
    vpc_id = aws_vpc.the_vpc.id

    # INGRESS: Who to allow to connect via SSH
    ingress {
        from_port   = 22 # 22 is standard SSH port
        to_port     = 22
        protocol    = "tcp"
    #    cidr_blocks = ["0.0.0.0/0"] # <-- Bootstrapping code (Change to one of other options after boostrapping phase)
        cidr_blocks = ["76.184.239.32/32"] # Via IP whitelist only
    }
    # Allow HTTP for Web App
    ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    }

    # If running frontend/backend on custom ports (e.g. 3000 / 8000) directly:
    # ingress {
    #   from_port   = 3000
    #   to_port     = 3000
    #   protocol    = "tcp"
    #   cidr_blocks = ["0.0.0.0/0"]
    # }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"] 
    }
}