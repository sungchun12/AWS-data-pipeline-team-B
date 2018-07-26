resource "aws_vpc_dhcp_options" "ima-flebx-dhcp" {
  domain_name         = "${var.DnsZoneName}"
  domain_name_servers = ["AmazonProvidedDNS"]

  tags {
    Name     = "ima-flebx-dhcp"
    Owner    = "${var.tags["Owner"]}"
    Email    = "${var.tags["Email"]}"
    Location = "${var.tags["Location"]}"
  }
}

resource "aws_vpc_dhcp_options_association" "dns_resolver" {
  vpc_id          = "${aws_vpc.ima-flexb-vpc.id}"
  dhcp_options_id = "${aws_vpc_dhcp_options.ima-flebx-dhcp.id}"
}

/* DNS PART ZONE AND RECORDS */
resource "aws_route53_zone" "main" {
  name    = "${var.DnsZoneName}"
  vpc_id  = "${aws_vpc.ima-flexb-vpc.id}"
  comment = "DNS Zone for IMA - FLEX team B"
}

resource "aws_route53_record" "ima-flexb-dns-test" {
  name    = "ima-flexb-dns-test.${var.DnsZoneName}"
  zone_id = "${aws_route53_zone.main.zone_id}"
  type    = "A"
  ttl     = 300
  records = ["${aws_instance.analytics-bastion.public_ip}"]
}
