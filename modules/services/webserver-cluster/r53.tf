#created record from existing host zone
resource "aws_route53_record" "www" {
  zone_id = "${data.aws_route53_zone.selected.zone_id}"
  name    = "${data.aws_route53_zone.selected.name}"
  type    = "A"
  alias {
    name            ="${aws_elb.ch2test.dns_name}"
    zone_id         ="${aws_elb.ch2test.zone_id}"
    evaluate_target_health = true
  }
}
     
