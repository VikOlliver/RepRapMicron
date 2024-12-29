// metricano.scad - A construction and prototyping kit based on 10mm centres, 5mm strips, and M3 fasteners
/*  Useful parts:
        metriccano_strip(holes)                 Single strip of holes
        metriccano_slot_strip(holes)          As above but all holes joined into an adjustable channel
        metriccano_l_plate(holes)              L-shaped plate
        metriccano_l_beam(holes)             Two strips of holes joined in an L-shaped beam
        metriccano_square_strip(holes)     A square section strip with vert & horiz holes, ends slotted for nuts.
        metriccano_plate(x,y)                    Plate with X holes in one direction, Y in the other.
        metriccano_base_anchor(holes)     Upended angle beam with a 3x3 base plate
        metriccano_woodscrew_clip(holes) Allows fixing 1u tall objects with C/S woodscrews
*/

metriccano_unit=10;             // Our basic size unit.
metriccano_hole_spacing=metriccano_unit;  // Nice 10mm grid for holes
metriccano_plate_height=metriccano_unit/2;
metriccano_strip_width=metriccano_unit;
// Yes, this is repeating an M3 library but in theory you can change this to M4 etc.
metriccano_screw_rad=3.4/2; // M3 screw hole radius
metriccano_nut_max_width=6.6;     // Nut from point to point
metriccano_nut_height=2.5;
metriccano_nut_min_width=5.8;  // Nut from flat to flat

// Hole for M3 screw, octagonal. Should print flat and vertical.
module  lose_screw_hole(screw_len=metriccano_hole_spacing*2.01) {
    rotate([180,0,360/16]) cylinder(h=screw_len,r=metriccano_screw_rad*1.2,$fn=8,center=true);
}

module metriccano_round_unit(height=metriccano_plate_height) {
    cylinder(h=metriccano_plate_height,r=metriccano_strip_width/2);
}

module metriccano_square_unit(height=metriccano_plate_height) {
    translate([0,0,metriccano_plate_height/2]) cube([metriccano_unit,metriccano_unit,metriccano_plate_height],center=true);
}

// A convenient 8ga countersunk woodscrew hole for fixing things to base boards with.
module metriccano_woodscrew() {
    cylinder(h=metriccano_unit*10,r=2.25,center=true,$fn=24);
    cylinder(h=4,r1=4,r2=2.25,$fn=24);
}

// A straight strip of Metriccano. Vertical holes go along the X axis
// h    number of holes
module metriccano_strip(h) {
    holes=floor(h+0.5);
    difference() {
        hull() {
            translate([(holes-1)*metriccano_hole_spacing,0,0]) metriccano_round_unit();
            metriccano_round_unit();
        }
        for (i=[0:holes-1]) translate([i*metriccano_hole_spacing,0,0]) lose_screw_hole();
    }
}

// A straight strip of Metriccano with a vertical slot along it allowing adjustment
// h    length of slot in merticcano units
module metriccano_slot_strip(h) {
    holes=floor(h+0.5);
    difference() {
        hull() {
            translate([(holes-1)*metriccano_hole_spacing,0,0]) metriccano_round_unit();
            metriccano_round_unit();
        }
        hull() {
            lose_screw_hole();
            translate([(holes-1)*metriccano_hole_spacing,0,0]) lose_screw_hole();
        }
    }
}

module metriccano_l_plate(holes) union() {
    metriccano_strip(holes);
    rotate([0,0,90]) metriccano_strip(holes);
}

// Not intended as an end part. It's a strip with a wide flat edge down one side. Useful for adding tabs
// h is the number of holes
// squared=true squares off the nearest end
module metriccano_tab_module(h,squared=false) {
    holes=floor(h+0.5);
    difference() {
        hull() {
            // Rounded far end
            translate([(holes-1)*metriccano_hole_spacing,0,0])
                if (squared) {
                    // Square edge
                    metriccano_square_unit();
                } else {
                    // Round edge
                    metriccano_round_unit();
                }
            translate([-metriccano_hole_spacing/2,-metriccano_strip_width,0]) cube([holes*metriccano_hole_spacing,metriccano_strip_width,metriccano_plate_height]);
            // Rounded near end
            metriccano_round_unit();
        }
        for (i=[0:holes-1]) translate([i*metriccano_hole_spacing,0,0]) lose_screw_hole();
    }
}


// A beam with an L-shaped cross section.  Holes go along the X axis, L cavity faces +Y
// h    number of holes
module metriccano_l_beam(h) union() {
    metriccano_tab_module(h);
    translate([0,-metriccano_plate_height,0]) rotate([90,0,0]) translate([0,metriccano_strip_width,0]) metriccano_tab_module(h);
}

// a 1x3 hole triangular plate with additional hole to allow 45 degree junctions
module metriccano_angle_plate_1x3() {
    difference() {
        hull() {
            metriccano_round_unit();
            translate([metriccano_hole_spacing,0,0]) metriccano_round_unit();
            translate([0,metriccano_hole_spacing,0]) metriccano_round_unit();
            translate([0,2*metriccano_hole_spacing,0]) metriccano_round_unit();
        }
        lose_screw_hole();
        translate([metriccano_hole_spacing,0,0]) lose_screw_hole();
        translate([0,metriccano_hole_spacing,0]) lose_screw_hole();
        translate([0,2*metriccano_hole_spacing,0]) lose_screw_hole();
        // 45 degree junction hole
        rotate([0,0,45]) translate([metriccano_hole_spacing,0,0]) lose_screw_hole();
    }
}

// A straight strip of Metriccano. Horizontal and vertical holes go along the X axis
// h    number of holes
module metriccano_square_strip(h) {
    holes=floor(h+0.5);
    difference() {
        hull() {
            translate([(holes-1.5)*metriccano_hole_spacing,-metriccano_hole_spacing/2,0]) cube(metriccano_strip_width);
            translate([-metriccano_hole_spacing/2,-metriccano_hole_spacing/2,0]) cube(metriccano_strip_width);
        }
        // long sides holes
        for (i=[0:holes-1]) translate([i*metriccano_hole_spacing,0,0]) {
            // Vertical hole
            lose_screw_hole();
            // Horizontal hole
            translate([0,0,metriccano_strip_width/2]) rotate([90,0,0]) lose_screw_hole();
        }
        // If we have room, pierce both ends and hide nuts in them. Ouch.
        // Otherwide just perforate the dude
        if (holes<3) {
            translate([0,0,metriccano_plate_height]) rotate([0,-90,0]) 
                    lose_screw_hole(metriccano_unit*10);
        } else {
            translate([0,0,metriccano_plate_height]) rotate([0,-90,0]) 
            {
                    lose_screw_hole();
                    translate([(metriccano_strip_width-metriccano_nut_max_width)/2,0,-metriccano_plate_height])
                        cube([metriccano_strip_width,metriccano_nut_min_width,metriccano_nut_height],center=true);
            }
            translate([(holes-1)*metriccano_hole_spacing,0,metriccano_plate_height]) rotate([0,90,0]) 
            {
                    lose_screw_hole();
                    translate([(metriccano_strip_width-metriccano_nut_max_width)/-2,0,-metriccano_plate_height])
                        cube([metriccano_strip_width,metriccano_nut_min_width,metriccano_nut_height],center=true);
            }
        }
    }
}

// An upended angle beam with a 3x3 base plate, base hole missing on the interior angle
module metriccano_base_anchor(length) {
    difference() {
        union() {
            metriccano_plate(3,3);
            // Fill unused holes
            translate([metriccano_unit/2,metriccano_unit/2,0])
                cube([metriccano_unit*2,metriccano_unit*2,metriccano_plate_height]);
        }
        // Chop out one corner
        translate([metriccano_unit,metriccano_unit,-metriccano_unit]) cube(metriccano_unit*3);
    }
    // L-Column of mounting holes
    translate([metriccano_unit/2,metriccano_unit*2,metriccano_unit*length]) rotate([0,90,0])
        metriccano_tab_module(length,squared=true);
    translate([metriccano_unit*2,metriccano_unit,metriccano_unit*length]) rotate([0,90,-90]) 
        metriccano_tab_module(length,squared=true);
    // Square spine filling the gap
    translate([metriccano_unit/2,metriccano_unit/2,0])
        cube([metriccano_unit/2,metriccano_unit/2,metriccano_unit*(length+0.5)]);
}

module metriccano_plate(x,y) {
    x_holes=floor(x+0.5);
    y_holes=floor(y+0.5);
    difference() {
        hull() {
            translate([(x_holes-1)*metriccano_hole_spacing,0,0]) metriccano_round_unit();
                metriccano_round_unit();
            translate([(x_holes-1)*metriccano_hole_spacing,(y_holes-1)*metriccano_hole_spacing,0]) 
                metriccano_round_unit();
            translate([0,(y_holes-1)*metriccano_hole_spacing,0]) metriccano_round_unit();
        }
        for(j=[0:y_holes-1])
            for (i=[0:x_holes-1])
                translate([i*metriccano_hole_spacing,j*metriccano_hole_spacing,0]) lose_screw_hole();
    }
}

// Clips a metriccano strip to a surface with a countersunk woodscrew or M4 fastener
module metriccano_woodscrew_clip(holes) {
    difference() {
        // Body
        cube([metriccano_unit*holes,metriccano_unit*2,metriccano_unit*1.5]);
        // L cavity in body
        translate([-metriccano_unit,metriccano_unit,metriccano_unit/2])
            cube([metriccano_unit*(holes+2),metriccano_unit*2,metriccano_unit*2]);
        // Screw hole
        translate([holes*metriccano_unit/2,metriccano_unit/2,-0.001]) {
            metriccano_woodscrew();
        }
    }
    // Bumps to ensure engagement with holes in retained strip
    for (i=[1:holes])
        translate([(i-0.5)*metriccano_unit,metriccano_unit*1.5,metriccano_unit/2])
            sphere(metriccano_screw_rad,$fn=24);
        
}

// Flat matrix of holes
//metriccano_plate(4,4);
// Basic strip
//metriccano_strip(10);
// Slotted strip
//metriccano_slot_strip(4);
// Square strip with holes both ways and hidden nuts
//metriccano_square_strip(5);
//Two strips of holes joined in an L-shaped beam
//metriccano_l_beam(6);
// For screwing things down to the bench
// metriccano_woodscrew_clip(2);