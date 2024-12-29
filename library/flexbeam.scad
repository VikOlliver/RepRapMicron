// flexbeam.scad - Flexure beam generator
// rounded_flexure_beam(x1,y1,x2,y2);
//  Generates a beam frm x1,y1 to x2,y2 with rounded ends
//  Setting "double=false" will only put the flexure on the x1,y1 end
//
// rounded_beam(x1,y1,x2,y2);
// As above, no flexure joints

default_beam_height=8;
beam_width=6;
// The smallest flexure I'm going to make with this setup.
minimal_flexure_length=beam_width*2;

// Function to calculate the distance between two points
function distance(x1,y1,x2,y2) = sqrt(pow(x1-x2, 2) + pow(y1-y2, 2));

module rotateToPoint(x1,y1,x2,y2) {
    // Calculate the direction vector from point1 to point2
    deltax = x2 - x1;
    deltay = y2 - y1;
    
    // Calculate the rotation angles needed to align the direction vector with the XY plane and the Z-axis
    angle_xy = atan2(deltax, deltay);
    // Rotate the object to align with the direction vector
    rotate([0, 0, -angle_xy]) children();// Rotate around Z-axis to align with XY plane
}

// Puts a rounded beam between two points.
// Note that the endpoint is within the radius of the endcap.
module rounded_beam(pointx1,pointy1,pointx2,pointy2,beam_height=default_beam_height) {
    translate([pointx1,pointy1,0]) cylinder(h=beam_height,r=beam_width/2,$fn=5*beam_width);
    translate([pointx2,pointy2,0]) cylinder(h=beam_height,r=beam_width/2,$fn=5*beam_width);
    translate([pointx1,pointy1,0]) rotateToPoint(pointx1,pointy1,pointx2,pointy2) 
        translate([-beam_width/2,0,0]) cube([beam_width,distance(pointx1,pointy1,pointx2,pointy2),beam_height]);
}

// Puts a beam with rounded flexures between two points.
// Note that the endpoint is within the radius of the endcap.
flexure_length=2;
flexure_width=0.8;

// A cutout to make a flexure shape along the Y axis poisitioned in -X
flexfn=30;  // Fineness of a flexure curve
flexrad=(beam_width-flexure_width)/4;   // A cylinder that fits within the flexure indent
module flexure_cutout(beam_height) translate([flexrad,-flexure_length-flexrad,0]) {
    // Staring curve on end nearest beam end.
    difference() {
        translate([-flexrad,flexrad,0]) cube([flexrad*2,flexrad*2,beam_height*3],center=true);
        cylinder(h=beam_height*4,r=flexrad,center=true,$fn=flexfn);
    }
    // Curve leading to beam end end of flexure flexure
    translate([0,flexrad*2,0])
        cylinder(h=beam_height*3,r=flexrad,center=true,$fn=flexfn);
    // Whack out the flexure
    translate([-flexrad,flexure_length/2+flexrad*2,0])
        cube([beam_width-flexure_width,flexure_length,beam_height*3],center=true);
    // Curve leading to beam body end of flexure flexure
    translate([0,flexrad*2+flexure_length,0])
        cylinder(h=beam_height*3,r=flexrad,center=true,$fn=flexfn);
    difference() {
        translate([-flexrad,flexure_length+3*flexrad,0]) cube([flexrad*2,flexrad*2,beam_height*3],center=true);
        translate([0,flexrad*4+flexure_length,0])
            cylinder(h=beam_height*4,r=flexrad,center=true,$fn=flexfn);
    }
}

// A pair of flexures ready to straddle a beam along the Y axis
module flexure_cutout_pair(beam_height) {
    flexure_cutout(beam_height);
    scale([-1,1,1]) translate([-beam_width,0,0]) flexure_cutout(beam_height);
}

module rounded_flexure_beam(pointx1,pointy1,pointx2,pointy2,double=true,beam_height=default_beam_height) {
    translate([pointx1,pointy1,0]) cylinder(h=beam_height,r=beam_width/2,$fn=5*beam_width);
    translate([pointx2,pointy2,0]) cylinder(h=beam_height,r=beam_width/2,$fn=5*beam_width);
    translate([pointx1,pointy1,0]) rotateToPoint(pointx1,pointy1,pointx2,pointy2) 
        translate([-beam_width/2,0,0]) {
            // This is the "beam" which starts at the rounded endpoint
            difference() {
                cube([beam_width,distance(pointx1,pointy1,pointx2,pointy2),beam_height]);
                translate([0,beam_width,0]) flexure_cutout_pair(beam_height);
                if (double)
                    translate([0,distance(pointx1,pointy1,pointx2,pointy2)-beam_width,0]) flexure_cutout_pair(beam_height);
            }
        }
}
 
// Flat S-shaped spring, intended to let your nuts wiggle etc.
module s_spring(ss_len,ss_width,ss_thick,ss_thin) {
    // There are 6 radius quadrants across the spring
    ss_rad=ss_width/5;
    ss_fn=7*ss_rad; // Generous resolution on curves
    // Main spring element goes along the length, allow a quadrant curve at each end.
    cube([ss_len-2*ss_rad,ss_thin,ss_thick],center=true);
    // A half-circle curve
    translate([ss_rad-ss_len/2,ss_rad-ss_thin/2,0]) difference() {
        // Make a tube
        cylinder(h=ss_thick,r=ss_rad,center=true,$fn=ss_fn);
        cylinder(h=ss_thick*2,r=ss_rad-ss_thin,center=true,$fn=ss_fn);
        // Chop half off
        translate([ss_rad*3,0,0]) cube(ss_rad*6,center=true);
    }
    // A half-circle curve for the other end
    translate([ss_len/2-ss_rad,ss_thin/2-ss_rad,0]) difference() {
        // Make a tube
        cylinder(h=ss_thick,r=ss_rad,center=true,$fn=ss_fn);
        cylinder(h=ss_thick*2,r=ss_rad-ss_thin,center=true,$fn=ss_fn);
        // Chop half off
        translate([-ss_rad*3,0,0]) cube(ss_rad*6,center=true);
    }
    // A half-length straight
    x=ss_len/2-2*ss_rad+ss_thin/2;
    translate([x/2+ss_rad-ss_thin/2,ss_thin-2*ss_rad,0]) cube([x,ss_thin,ss_thick],center=true);
    // Quarter curve to finish this end
    translate([ss_rad-ss_thin/2,-ss_rad*3+1.5*ss_thin,0]) difference() {
        // Make a tube
        cylinder(h=ss_thick,r=ss_rad,center=true,$fn=ss_fn);
        cylinder(h=ss_thick*2,r=ss_rad-ss_thin,center=true,$fn=ss_fn);
        translate([ss_rad*3,0,0]) cube(ss_rad*6,center=true);
        translate([0,-ss_rad*3,0]) cube(ss_rad*6,center=true);
    }
    // A half-length straight
    translate([-x/2-ss_rad,2*ss_rad-ss_thin,0]) cube([x,ss_thin,ss_thick],center=true);
    // Quarter curve to finish top end
    translate([-ss_rad,ss_rad*3-1.5*ss_thin,0]) difference() {
        // Make a tube
        cylinder(h=ss_thick,r=ss_rad,center=true,$fn=ss_fn);
        cylinder(h=ss_thick*2,r=ss_rad-ss_thin,center=true,$fn=ss_fn);
        translate([-ss_rad*3,0,0]) cube(ss_rad*6,center=true);
        translate([ss_rad*3,ss_rad*3,0]) cube(ss_rad*6,center=true);
        translate([0,ss_rad*3,0]) cube(ss_rad*6,center=true);
    }
}
// Test with sides
/*rounded_flexure_beam(0,60,0,10);
rounded_flexure_beam(50,50,50,0);
rounded_beam(0,10,50,0);
rounded_beam(0,60,50,50);
vertical_flexure(30,20,15);*/
