// probe_electrolysis_grip - Holds a probe wire in place while the end is electro-etched
// (c)2024 vik@diamondage.co.nz, released under GPL V3 or later.
// Note: Values given fit a standard 45mm urine sample container

wire_rad=0.6;
grip_tab_height=10;
grip_tab_width=5;
grip_tab_thick=3;   // Offset the assembly so that the grip is thinner.
wall=2;
pot_max_rad=45.6/2;
pot_min_rad=41.2/2;
brim_height=20;
bar_width=11;
bar_height=8;

// A shape like the top entrance to the pot
module pot_model() {
    difference() {
        cylinder(h=brim_height,r=pot_max_rad,$fn=64);
        cylinder(h=brim_height,r=pot_min_rad,$fn=64);
    }
}

module pot_lid() difference() {
    // Start with a cylinder that is bigger than the pot
    cylinder(h=brim_height,r=pot_max_rad+wall,$fn=64);
    // Chop out the pot brim
    translate([0,0,bar_height]) pot_model();
    // Leave the bar height in the moddle clear
    translate([0,0,bar_height]) cylinder(h=brim_height,r=pot_min_rad-wall,$fn=64);
}

module electro_grip() difference() {
    union() {
        // Keep the bot on the middle of the lid that is the width of the bar.
        intersection() {
            pot_lid();
            translate([bar_width/2-grip_tab_thick,bar_width/2,0]) cube([bar_width,pot_max_rad*4,brim_height*4],center=true);
        }
        // Add a tab to clip the wire onto. Put a notch in it for croc clip
        translate([-grip_tab_thick,-grip_tab_width/2,-grip_tab_height]) difference() {
            cube([grip_tab_thick,grip_tab_width,grip_tab_height]);
            translate([grip_tab_thick,0,grip_tab_height-6]) cube([1,grip_tab_width*3,4],center=true);
        }
    }
    // punch a hole in the middle for the wire
    translate([wire_rad,0,0]) cylinder(h=bar_height*5,r=wire_rad,center=true,$fn=6);
}

translate([0,0,grip_tab_thick]) rotate([0,-90,0])
electro_grip();