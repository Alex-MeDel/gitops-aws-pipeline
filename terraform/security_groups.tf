resource "aws_security_group" "the_sg" {
    name   = "the-sg"
    description = "Security rules"
    vpc_id = aws_vpc.the_vpc.id

    # INGRESS: Who to allow to connect via SSH
    ingress {
        from_port   = 22 # 22 is standard SSH port
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"] # <-- Bootstrapping code (Change to one of other options after boostrapping phase)
    #    cidr_blocks = ["10.0.0.0/16"] # Via Client VPN only
    #    cidr_blocks = ["IP_ADDRESS/32"] # Via IP whitelist only
    }
    # EGRESS: block from talking to the public internet
    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"] # BOOTSTRAPPING - Comment out when finished boostrapping
    #    cidr_blocks = ["127.0.0.1/32"] # Block all outbound, uncomment after boostrapping
    }
}