// pika_version.scad - Version labelling for PIKA RepRapMicron

version_string="PIKA V0.02";

// 0.6mm thick text, 5mm tall, vertical, flat on XY plane
module version_text() {
    translate([0,0,-0.3]) linear_extrude(0.6) {
        text(version_string, size = 4, halign = "center", valign = "center", $fn = 16);
    }
}
