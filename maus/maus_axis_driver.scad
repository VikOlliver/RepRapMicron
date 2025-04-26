// maus_axis_driver.scad - RepRapMicron motion stage
// (c)2024 vik@diamondage.co.nz, released under the terms of the GPL V3 or later
// One Maus Axis Diver. Three are needed for the complete Maus mechanism
version_string="MAUS V0.03";

include <../library/m3_parts.scad>
include <../library/nema17lib.scad>
include <../library/metriccano.scad>
include <flexure_linear_coupling.scad>

flexure_width=6;        // Reduced from original 7.
flexure_length=2.5;
flexure_height=1.0;     // For DIAS PLA, 1 is about right. Testing 0.8 for stiffer filament
vertical_flexure_length=8;
vertical_flexure_height=6;
vertical_flexure_width=8;   // Width of the anchor block
vertical_flexure_thick=8.2; // Width of the actual flexing bit

// Used to fiddle flexures. Just over one layer...
layer_height=0.21;
wall=2;                         // Arbitrary rigid wall thickness

// These define the size and mechanical advantage of the whole mechanism. Overall dimensions change to suit.
/*axis_arm_ratio=2.5;
axis_lifter_length=25;
axis_arm_length=axis_lifter_length*axis_arm_ratio;*/
axis_lifter_length=24;
axis_arm_length=72;
axis_arm_ratio=axis_arm_length/axis_lifter_length;
echo(str("Arm ratio=",axis_arm_ratio));

axis_probe_depression=2;       // Shouldn't this be 4 not 2?

/* Valuse used for the original Z axis
axis_arm_ratio=4;
axis_lifter_length=14;
axis_probe_depression=2;
*/


axis_motion_clearance=axis_probe_depression+0.5;    // This should clear moving parts...
axis_arm_width=12;
axis_lifter_width=flexure_width;
axis_lifter_height=4;
axis_platform_height=40;   // Height of the Z platform with mounting holes in.
axis_platform_thick=3;        // Thickness of Z platform with holes in.
platform_pivot_width=30;    // Maximum horizontal separation of flexures (edge to edge) on platform
platform_surface_width=40;  // Horizontal dimension of platform surface (Y axis)

// The fixed block on which the platform pivots
axis_anchor_block_length=platform_pivot_width;
axis_anchor_block_width=8;
axis_anchor_block_height=7;
axis_arm_height=axis_anchor_block_height+axis_motion_clearance;
axis_drive_pivot_x=axis_arm_length-axis_arm_length/axis_arm_ratio;  // Z drive flexure on X
axis_nut_holder_rad=6;                 // Diameter of the thing that holds the drive nut
axis_drive_nut_x=axis_drive_pivot_x+flexure_length/2+axis_nut_holder_rad;           // Z drive nut on X
drive_lug_length=18;                    // Length of the transverse drive lug bar.
axis_top_bearing_z=29;             // Bottom of the bearing block is this far off the base

// Where the flat, long arm starts near the anchor
axis_end_bend_x=axis_anchor_block_width+flexure_length/2+axis_motion_clearance;

// Function to calculate the distance between two points
function distance(x1,y1,x2,y2) = sqrt(pow(x1-x2, 2) + pow(y1-y2, 2));

// 0.6mm thick text, 5mm tall, vertical, flat on XY plane
module version_text() {
    translate([0,0,-0.3]) linear_extrude(0.6) {
        text(version_string, size = 4, halign = "center", valign = "center", $fn = 16);
    }
}

// Mounting plate for a NEMA17 motor with rounded corners,
// Extended width for metriccano mounting
// nema_late_thick - Thickness of NEMA mounting plate
// nema_corner_rad - radius of rounded corners
module nema17_plate(nema_plate_thick=5,nema_corner_rad=2) difference() {
    rad_loc=(5*metriccano_unit-nema_corner_rad)/2-1;
    hull() {
        // +Y side
        translate([rad_loc,rad_loc+metriccano_unit,0]) cylinder(h=nema_plate_thick,r=nema_corner_rad);
        translate([-rad_loc,rad_loc/2+metriccano_unit,0]) cylinder(h=nema_plate_thick,r=nema_corner_rad);
        // _Y side
        translate([rad_loc,-rad_loc-metriccano_unit,0]) cylinder(h=nema_plate_thick,r=nema_corner_rad);
        translate([-rad_loc,-rad_loc/2-metriccano_unit,0]) cylinder(h=nema_plate_thick,r=nema_corner_rad);
        // Central markers where we start narrowing the end down
        translate([0,-rad_loc-metriccano_unit,0])
            cylinder(h=nema_plate_thick,r=nema_corner_rad);
        translate([0,rad_loc+metriccano_unit,0])
            cylinder(h=nema_plate_thick,r=nema_corner_rad);

    }
    // Screw holes
    translate([nema17_screw_sep/2,nema17_screw_sep/2,0]) cylinder(h=nema_plate_thick*3,r=m3_screw_rad,$fn=16,center=true);
    translate([-nema17_screw_sep/2,nema17_screw_sep/2,0]) cylinder(h=nema_plate_thick*3,r=m3_screw_rad,$fn=16,center=true);
    translate([nema17_screw_sep/2,-nema17_screw_sep/2,0]) cylinder(h=nema_plate_thick*3,r=m3_screw_rad,$fn=16,center=true);
    translate([-nema17_screw_sep/2,-nema17_screw_sep/2,0]) cylinder(h=nema_plate_thick*3,r=m3_screw_rad,$fn=16,center=true);
     // Collar hole
    cylinder(h=nema_plate_thick*3,r=nema17_collar_rad,center=true);
}

// A NEMA17 plate with nutted Metriccano mounting holes, pillars to prop up the axis flexure mechanism,
// and hold a limit switch.
// Why does it have a separate base plate? Because M3 screws come in standard lengths and it needs a spacer.
axis_motor_pillar_height=35;
limit_switch_level=30.3;    // Height to the top of the limit switch bar
motor_pillar_spacing=6*metriccano_unit;     // Pillar holes, centre to centre
motor_base_thick=10;

module axis_motor_pillar_assy() {
    difference() {
        union() {
            nema17_plate(motor_base_thick);
            // Mounting hole pillars, joined for strength
            hull() {
                // Screw pillars
                translate([metriccano_unit,-motor_pillar_spacing/2,motor_base_thick]) cylinder(h=axis_motor_pillar_height,r=metriccano_plate_height);
                translate([2*metriccano_unit,-motor_pillar_spacing/2,motor_base_thick]) cylinder(h=axis_motor_pillar_height,r=metriccano_plate_height);
                // Reinforcement
                translate([2*metriccano_unit,5-motor_pillar_spacing/2,motor_base_thick]) cylinder(h=axis_motor_pillar_height,r=metriccano_plate_height);
            }
            hull() {
                // Screw pillars
                translate([metriccano_unit,motor_pillar_spacing/2,motor_base_thick])
                    cylinder(h=axis_motor_pillar_height,r=metriccano_plate_height);
                translate([2*metriccano_unit,motor_pillar_spacing/2,motor_base_thick])
                    cylinder(h=axis_motor_pillar_height,r=metriccano_plate_height);
                // Reinforcement
                translate([2*metriccano_unit,motor_pillar_spacing/2-5,motor_base_thick])
                    cylinder(h=axis_motor_pillar_height,r=metriccano_plate_height);
            }
            // Version info
            translate([-2.5*metriccano_unit,0,motor_base_thick/2]) rotate([90,0,-90]) version_text();
            // Limit switch holder
            translate([metriccano_unit*2.25,0,limit_switch_level/2+motor_base_thick])
                difference() {
                    // Body of limit switch block
                    cube([metriccano_unit/2,motor_pillar_spacing,limit_switch_level],center=true);
                    // Gaps for NEAM moutn screws & washers
                    translate([0,nema17_screw_sep/2,-limit_switch_level/2]) rotate([0,90,0]) rotate([0,0,45])
                        cube([6,6,metriccano_unit],center=true);
                    translate([0,-nema17_screw_sep/2,-limit_switch_level/2]) rotate([0,90,0]) rotate([0,0,45])
                        cube([6,6,metriccano_unit],center=true);
                    // Captive nuts and holes, and wire slots to hold limit switch wires in place ???
                    translate([0,metriccano_unit/2,limit_switch_level/2-5]) {
                        rotate([0,-90,0]) {
                            translate([0,0,-metriccano_unit/4]) m3_nut_cavity_tapered(captive=true);
                            m3_screw_hole(metriccano_unit);
                        }
                        // Wire slot
                        translate([-metriccano_unit/4,-1-metriccano_screw_rad,-metriccano_unit/2])
                            cylinder(h=limit_switch_level/2,r=0.5,$fn=24);
                        // Wire via
                        translate([0,8,-8]) rotate([0,90,0]) m3_screw_hole(metriccano_unit*2);
                    }
                    translate([0,-metriccano_unit/2,limit_switch_level/2-5]) {
                        rotate([0,-90,0]) {
                            translate([0,0,-metriccano_unit/4]) m3_nut_cavity_tapered(captive=true);
                            m3_screw_hole(metriccano_unit);
                        }
                        // Wire slot
                        translate([-metriccano_unit/4,1+metriccano_screw_rad,-metriccano_unit/2])
                            cylinder(h=limit_switch_level/2,r=0.5,$fn=24);
                        // Wire via
                        translate([0,-8,-8]) rotate([0,90,0]) m3_screw_hole(metriccano_unit*2);
                    }
                }
        }
        // Mounting rail screw holes
        translate([metriccano_unit,-3*metriccano_unit,-0.001]) {
            cylinder(h=axis_motor_pillar_height*3,r=m3_screw_rad,$fn=16,center=true);
            m3_nut_cavity_tapered(captive=true) ;
        }
        translate([metriccano_unit,3*metriccano_unit,-0.001]) {
            cylinder(h=axis_motor_pillar_height*3,r=m3_screw_rad,$fn=16,center=true);
            m3_nut_cavity_tapered(captive=true) ;
        }
        // A line of holes in a strip, half the thickness of the hole spacing, headed in -X
        // The number of holes will be rounded up to an integer.
        translate([2*metriccano_unit,3*metriccano_unit,-0.001]) {
            cylinder(h=axis_motor_pillar_height*3,r=m3_screw_rad,$fn=16,center=true);
            m3_nut_cavity_tapered(captive=true) ;
        }
        translate([2*metriccano_unit,-3*metriccano_unit,-0.001]) {
            cylinder(h=axis_motor_pillar_height*3,r=m3_screw_rad,$fn=16,center=true);
            m3_nut_cavity_tapered(captive=true) ;
        }
    }
}

// A flexure join scalloped in case anyone tries printing it on the surface of the print bed
module flexure_tab() difference() {
    translate([0,0,flexure_height/2]) cube([flexure_length+1,flexure_width,flexure_height],center=true);
    // Scalop the top of the flexure
    translate([0,0,flexure_height]) scale([0.6,1,flexure_height/20]) rotate([90,0,0]) cylinder(h=flexure_width+1,r=flexure_length/2,center=true);
    // Undercut the flexure so it does not touch print bed
    translate([0,0,0.1]) cube([flexure_length*0.6,flexure_width*3,layer_height],center=true);
}

// A vertical flexure join scalloped in case anyone tries printing it on the surface of the print bed
// Wedge used for each side
module vertical_flexure_wedge(t) hull() {
    translate([0,(t+vertical_flexure_width)/2,0]) cube([vertical_flexure_length/2,vertical_flexure_width,vertical_flexure_height*3],center=true);
    translate([0,t+vertical_flexure_width,0]) cube([vertical_flexure_length,vertical_flexure_width,vertical_flexure_height*3],center=true);
    }

module vertical_flexure(thick=vertical_flexure_thick) difference() {
    translate([0,0,vertical_flexure_height/2]) cube([vertical_flexure_length+1,vertical_flexure_width,vertical_flexure_height],center=true);
    // Scalop the sides of the flexure. Use a blunt wedge
    vertical_flexure_wedge(thick);
    scale([1,-1,1]) vertical_flexure_wedge(thick);
    // Undercut the flexure so it does not touch print bed
    translate([0,0,0.1]) cube([vertical_flexure_length/2,flexure_width*3,layer_height],center=true);
}

// Flexure join for printing in mid-air. Basically one layer height thinner
module flexure_tab_unsupported() difference() {
    translate([0,0,flexure_height/2]) cube([flexure_length+1,flexure_width,flexure_height],center=true);
    // Scalop the top of the flexure. The cube makes sure the scalop clears the upper surface
    translate([0,0,flexure_height-layer_height]) {
        scale([0.6,1,flexure_height/20]) rotate([90,0,0]) cylinder(h=flexure_width+1,r=flexure_length/2,center=true);
        translate([0,0,flexure_height/2]) cube([flexure_length*0.6,flexure_width+1,flexure_height],center=true);
    }
}


// A block that anchors the moving parts to the Z axis
module axis_anchor_block() {
    translate([-flexure_length/2-axis_anchor_block_width,-axis_anchor_block_length/2,0])
        cube([axis_anchor_block_width,axis_anchor_block_length,axis_anchor_block_height]);
}

// These are used for all the lifting linkages in the tool end Z axis lifting section
module axis_lifter_linkage() {
    translate([0,0,axis_lifter_height/2])
        cube([axis_lifter_length,axis_lifter_width,axis_lifter_height],center=true);
}

// The lifter linkage with an unsupported flexure
module axis_unsupported_hinged_lifter_arm() {
    flexure_tab_unsupported();
    translate([(axis_lifter_length+flexure_length)/2,0,0]) axis_lifter_linkage();
    translate([axis_lifter_length+flexure_length,0,0]) flexure_tab_unsupported();
}

// The lifter linkage with the flexure raised so it won't touch the print bed.
module axis_hinged_lifter_arm() {
    flexure_tab();
    translate([(axis_lifter_length+flexure_length)/2,0,0]) axis_lifter_linkage();
    translate([axis_lifter_length+flexure_length,0,0]) flexure_tab();
}

// Block with mounting holes that is lifted on Z axis
module axis_platform() {
        difference() {
            translate([axis_platform_thick/2,0,axis_platform_height/2])
                cube([axis_platform_thick,platform_surface_width,axis_platform_height],center=true);
            // Mounting holes, 10mm spacing
            for (j=[1:platform_surface_width/10])
                for(i=[0:axis_platform_height/10-1])
                    translate([0,-platform_surface_width/2+j*10-5,i*10+5]) rotate([0,90,0]) rotate([0,0,180/8]) cylinder(h=axis_platform_thick*3,r=1.6,center=true,$fn=8);
        }
}

// Triangular brace mounting plate for Z axis frame
axis_bracing_height=30;
axis_bracing_top_width=wall*2;
axis_bracing_top_height=6;
module axis_bracing() translate([-flexure_length/2,0,0]) {
//    translate([-axis_drive_pivot_x/2,0,axis_bracing_height/2])
//        cube([axis_drive_pivot_x,wall*2,axis_bracing_height],center=true);
    // Thin side wall
    translate([-axis_drive_pivot_x/2,0,axis_bracing_height/2])
        cube([axis_drive_pivot_x,wall,axis_bracing_height],center=true);
    // Ridge along top
    // Ridge along top, carefully miss nut holes
    translate([-axis_drive_nut_x/2,0,axis_bracing_height-axis_bracing_top_height/2])
        cube([axis_drive_nut_x-m3_nut_max_width-flexure_length,axis_bracing_top_width,axis_bracing_top_height],center=true);
    /// Tapered bottom to the ridge to print without overhang
    hull() {
        // Minimal lower ridge
        translate([-axis_drive_pivot_x/2,0,axis_bracing_height-axis_bracing_top_height])
            cube([axis_drive_pivot_x,axis_bracing_top_width,0.01],center=true);
        // Minimal top of thin wall
        translate([-axis_drive_pivot_x/2,0,axis_bracing_height-axis_bracing_top_height-wall])
            cube([axis_drive_pivot_x,wall,0.01],center=true);
    }
    // Bottom of wall has to engage Metriccano strip
    translate([-axis_drive_pivot_x/2,0,metriccano_plate_height/2])
        cube([axis_drive_pivot_x,axis_bracing_top_height+1,metriccano_plate_height],center=true);
}

// Z axis drive nut holder
module axis_drive_nut_holder() {
    nut_holder_height=9;
    difference() {
        union() {
            // Cylindrical body with a rectangular area to attach a flexure to
            hull() {
                cylinder(h=nut_holder_height,r=axis_nut_holder_rad);
                translate([axis_nut_holder_rad,0,wall/2]) cube([wall,flexure_width,wall],center=true);
            }
            // The lower lugs for tensioning spring attachment
            difference() {
                union() {
                    // Horizontal octagonal lugs for easy printing.
                    translate([0,0,nut_holder_height-2.31]) rotate([90,0,0]) rotate([0,0,180/8])
                        cylinder(h=drive_lug_length,r=2.5,center=true);
                    // Security lines to hold lug during assembly
                    translate([0,0,layer_height]) difference() {
                        cube([1,axis_anchor_block_length,layer_height*2],center=true);
                        cube([2,drive_lug_length,layer_height*4],center=true);
                    }
                    // Props for lugs
                    translate([0,wall/2-drive_lug_length/2,nut_holder_height/2]) cube([wall*2,wall,nut_holder_height],center=true);
                    translate([0,wall/-2+drive_lug_length/2,nut_holder_height/2]) cube([wall*2,wall,nut_holder_height],center=true);
                }
            }
        }
        // Generously sized hole for drive screw
        cylinder(h=999,r=m3_screw_rad+0.5,center=true,$fn=32);
        // Tapered cavity to hold drive nut.
        translate([0,0,1]) cylinder(h=nut_holder_height+0.001,r1=m3_nut_max_width/2-0.55,r2=m3_nut_max_width/2,$fn=6);
    }
}

// The combined printable part holding the Z platform, all its linkages, and the Z drive coupling.
module axis_platform_assembly() {
    // Anchor block and bracing for Z platform linkages
    axis_anchor_block();
    // Sides
    translate([-axis_anchor_block_width-flexure_length/2,-axis_anchor_block_length/2,0])
        cube([axis_anchor_block_width,flexure_width,axis_platform_height]);
    translate([-axis_anchor_block_width-flexure_length/2,axis_anchor_block_length/2-flexure_width,0])
        cube([axis_anchor_block_width,flexure_width,axis_platform_height]);
    // Top it with another block
    translate([-flexure_length/2-axis_anchor_block_width,-axis_anchor_block_length/2,axis_platform_height]) {
        cube([axis_anchor_block_width,axis_anchor_block_length,3]);
        // A bit of a sloping on inside corners to reduce overhang droop
        translate([axis_anchor_block_width/2,flexure_width,0]) rotate([45,0,0])
            cube([axis_anchor_block_width,3,3],center=true);
        translate([axis_anchor_block_width/2,axis_anchor_block_length-flexure_width,0]) rotate([45,0,0])
            cube([axis_anchor_block_width,3,3],center=true);
    }

    // The located Z platform
    translate([axis_lifter_length+flexure_length*1.5,0,0]) axis_platform();

    // +Y lower linkage arm
    translate([0,(platform_pivot_width-flexure_width)/2,0]) axis_hinged_lifter_arm();
    // -Y lower linkage arm
    translate([0,-(platform_pivot_width-flexure_width)/2,0]) axis_hinged_lifter_arm();
    // +Y upper linkage arm
    translate([0,(platform_pivot_width-flexure_width)/2,axis_platform_height-flexure_height]) axis_unsupported_hinged_lifter_arm();
    // -Y upper linkage arm
    translate([0,-(platform_pivot_width-flexure_width)/2,axis_platform_height-flexure_height]) axis_unsupported_hinged_lifter_arm();
    // We'll just brace those top arms together, starting the bracing higher up than the flexures
    // to make sure it is all stable when printing in mid-air
    translate([flexure_length/2,-platform_pivot_width/2,axis_platform_height+wall/2]) 
        cube([wall*2,platform_pivot_width,wall]);
     translate([axis_lifter_length-wall*2+flexure_length/2,-platform_pivot_width/2,axis_platform_height+wall/2]) 
        cube([wall*2,platform_pivot_width,wall]);
     
    // Arbitrary pivot arm. Doubtless will need improvement.
    // Vertical pivot block
    translate([flexure_length/2,-axis_arm_width/2,0])
        cube([axis_lifter_length/2,axis_arm_width,axis_anchor_block_height+axis_motion_clearance]);
    // Brace joining lower two linkage arms
    translate([flexure_length/2+axis_lifter_length/4
     ,0,axis_lifter_height/2])
        cube([axis_lifter_length/2,platform_pivot_width,axis_lifter_height],center=true);
    translate([-axis_drive_pivot_x,0,0]) flexure_tab();

    // The arm that goes onto the Z screw
    // Arch over the frame, joining the lever and pivot block
    axis_arch_len=axis_end_bend_x+flexure_length+axis_lifter_length/2;
    axis_arch_height=6;
    translate([-axis_end_bend_x,-axis_arm_width/2,axis_anchor_block_height+axis_motion_clearance])
        cube([axis_arch_len-flexure_length/2,axis_arm_width,axis_arch_height]);
    // The arm with a block as long as the block on the lifter end. This tapers to meet the vertical flexure
    hull() {
        translate([-axis_end_bend_x+0.5,0,(axis_arm_height+axis_arch_height)/2])
            cube([1,axis_arm_width,axis_arm_height+axis_arch_height],center=true);
        translate([-axis_end_bend_x-axis_lifter_length/2+0.5,0,axis_arm_height/2])
            cube([1,vertical_flexure_width,axis_arm_height],center=true);
    }
    // Add a couple of flexures (these may or may not overlap depending on arm hieght but I don't care.
    translate([-axis_lifter_length/4-axis_end_bend_x-vertical_flexure_length,0,0])
        vertical_flexure();
    translate([-axis_lifter_length/4-axis_end_bend_x-vertical_flexure_length,0,axis_arm_height-vertical_flexure_height])
        vertical_flexure();
    hull() {
        // Space a 1mm block where one end of the flexure will go
        translate([-1-vertical_flexure_length*1.5-axis_lifter_length/4-axis_end_bend_x,0,axis_arm_height/2])
            cube([1,vertical_flexure_width,axis_arm_height],center=true);
        // Place a block of wall just before the driven flexure
        translate([flexure_length/2-axis_drive_pivot_x,-flexure_width/2,0]) cube([wall,flexure_width,wall]);
    }
    // Something to anchor it by, a couple of 4-hole mounting plates and 2x2 plates
    // Has to be *behind* the flexure or they'll bang on the edge of the mounting platform.
    translate([-axis_drive_nut_x,platform_pivot_width/2+metriccano_strip_width/2,0]) {
        metriccano_strip(axis_drive_nut_x/10);
        translate([metriccano_unit,0,0]) metriccano_plate(2,2);
    }
    translate([-axis_drive_nut_x,-platform_pivot_width/2-metriccano_strip_width/2,0]) {
        metriccano_strip(axis_drive_nut_x/10);
        translate([metriccano_unit,-metriccano_unit,0]) metriccano_plate(2,2);
    }

    // Brace mounting plates for axis frame
    // Fractional translation ensures boolean join
    translate([0,-axis_anchor_block_length/2+wall*0.999,0]) axis_bracing();
    translate([0,axis_anchor_block_length/2-wall*0.999,0]) axis_bracing();
    // Version text
    translate([-axis_drive_pivot_x/2-2,axis_anchor_block_length/2-wall/2,axis_bracing_height/2])
        rotate([90,0,180]) version_text();

    //Support pad for platform so it prints
    translate([axis_lifter_length+flexure_length*1.5-10,-wall,0]) intersection() {
        cube([10,2*wall,10]);
        rotate([0,45,0]) cube([50,5*wall,50]);
    }

    translate([-axis_drive_nut_x,0,0]) axis_drive_nut_holder();
}

axis_bearing_block_width=10;
axis_bearing_block_height=11;  // 1mm of this is actually on top of the bering block arms, so the block will be thinner

axis_bearing_clearance=5; // Allow this much room from the bearing axis for washers etc.
axis_bearing_bracing_len=20;   // Length of the bottom of the bearing bracing
// The lug poitions the tip on the origin, slightly raised above zero, the body heading out on Y+

// Block across the top of the supports that holds the bearing. Bearing is an M3 nut drilled out to 3mm.
// Made removable for ease of assembly
module axis_bearing_block() {
    // Rounded top bar with bearing hole in it
    difference() {
        hull() {
            translate([0,axis_bearing_block_width+axis_bearing_clearance,0]) cylinder(h=axis_bearing_block_height-1,r=axis_bearing_block_width/2);
            translate([0,-axis_bearing_block_width-axis_bearing_clearance,0]) cylinder(h=axis_bearing_block_height-1,r=axis_bearing_block_width/2);
        }
        // Bearing hole
        m3_screw_hole(axis_top_bearing_z*4);
        // Bearing nut, slightly proud to avoid booleans, rotated to maintain beam strength, undersize
        translate([0,0,axis_bearing_block_height-0.999-m3_nut_height])
            rotate([0,0,30]) scale([0.99,0.99,1]) m3_nut_cavity();
        // Anchor screw holes
        translate([0,-axis_bearing_block_width-axis_bearing_clearance,0]) m3_screw_hole(axis_top_bearing_z*4);
        translate([0,axis_bearing_block_width+axis_bearing_clearance,0])
            m3_screw_hole(axis_top_bearing_z*4);
        // Groves to hold tension bands
        translate([axis_bearing_block_width,m3_nut_max_width,0]) rotate([0,45,0])
            cylinder(h=axis_bearing_block_height*2,r=axis_bearing_block_width*0.6,center=true,$fn=32);
        translate([axis_bearing_block_width,-m3_nut_max_width,0]) rotate([0,45,0])
            cylinder(h=axis_bearing_block_height*2,r=axis_bearing_block_width*0.6,center=true,$fn=32);
        translate([-axis_bearing_block_width,m3_nut_max_width,0]) rotate([0,-45,0])
            cylinder(h=axis_bearing_block_height*2,r=axis_bearing_block_width*0.6,center=true,$fn=32);
        translate([-axis_bearing_block_width,-m3_nut_max_width,0]) rotate([0,-45,0])
            cylinder(h=axis_bearing_block_height*2,r=axis_bearing_block_width*0.6,center=true,$fn=32);
    }
}

// A pillar with a nut and M3x16 screw hole (less height of bearing block).
// Used to prop the axis_bearing_block up
module axis_vertical_bearing_support() difference() {
    union() {
        hull() {
            translate([0,axis_bearing_block_width+axis_bearing_clearance,axis_top_bearing_z]) cylinder(h=1,r=axis_bearing_block_width/2,$fn=30);
            translate([-axis_bearing_block_width/2,axis_anchor_block_length/2-wall*2,0])
                cube([axis_bearing_bracing_len,wall*2,metriccano_plate_height]);
        }
        translate([-axis_bearing_block_width/2,axis_bearing_block_width*1.5,0]) cube([axis_bearing_block_width,axis_bearing_block_width,axis_top_bearing_z]);
    }
    // Hole for bearing block retention screw
    translate([0,axis_bearing_block_width+axis_bearing_clearance,axis_top_bearing_z]) m3_screw_hole(16-(axis_bearing_block_height-1));
    // Slot for retaining nut for above
    translate([0,axis_bearing_block_width+axis_bearing_clearance,axis_top_bearing_z-4-m3_nut_height/2]) 
        rotate([0,0,90]) m3_nut_slot();
}

// Printable axis and linkages assembly
 module axis_complete() {
    axis_platform_assembly();
    translate([-axis_drive_nut_x,0,0]) union() {
        // +Y vertical bearing support
        axis_vertical_bearing_support();
        // -Y vertical bearing support
        scale([1,-1,1]) axis_vertical_bearing_support();
    }
}

// Manual thumbscrew
module manual_thumbscrew() difference() {
    union() {
        cylinder(h=4,r=15);
        translate([0,0,4]) cylinder(h=2,r1=8,r2=5);
    }
    m3_screw_hole(20);
    translate([0,0,4]) m3_nut_cavity();
}

// NEMA17 mount, basically used as a spacer and to stop nuts falling out
module nema17_horizontal_mount() {
    difference() {
            // Create something like a metriccano plate, slightly wider than NEMA17
            translate([0,0,metriccano_plate_height/2])
                cube([nema17_screw_sep+2*m3_screw_rad+4*wall,7*metriccano_unit+1,metriccano_plate_height],center=true);
        // Smack holes in mounting plate
        // Screw holes
        translate([nema17_screw_sep/2,nema17_screw_sep/2,0]) cylinder(h=metriccano_plate_height*3,r=m3_screw_rad,$fn=16,center=true);
        translate([-nema17_screw_sep/2,nema17_screw_sep/2,0]) cylinder(h=metriccano_plate_height*3,r=m3_screw_rad,$fn=16,center=true);
        translate([nema17_screw_sep/2,-nema17_screw_sep/2,0]) cylinder(h=metriccano_plate_height*3,r=m3_screw_rad,$fn=16,center=true);
        translate([-nema17_screw_sep/2,-nema17_screw_sep/2,0]) cylinder(h=metriccano_plate_height*3,r=m3_screw_rad,$fn=16,center=true);
         // Collar hole
        cylinder(h=metriccano_plate_height*3,r=nema17_collar_rad,center=true);
    }
}
// Metriccano NEMA17 mount, 5 hole horizontal strips.
// Might not be a good idea to mount it by the motor, but here's one if you need it...
module metriccano_nema17_horizontal_mount() {
        union() {
            nema17_horizontal_mount() ;
            // Stick a strip of Metriccano on each side
            translate([-2*metriccano_unit,4*metriccano_unit,0]) metriccano_strip(5);
            translate([-2*metriccano_unit,-4*metriccano_unit,0]) metriccano_strip(5);
        }
}



// Integrated stage. Has XY linkages and long flexures to connect XY drivers.
module integrated_stage() difference() {
    union() {
        difference() {
            // Join up the flexure blocks and the mounting plate
            union() {
                metriccano_flexure_block_bidirectional(4);
                translate([0,metriccano_unit*4.5,0]) 
                    scale([1,-1,1]) metriccano_flexure_block_bidirectional(4);
                translate([-metriccano_unit,metriccano_unit*0.75,0]) metriccano_plate(6,4);
                // Slap another mounting plate on top
                translate([-metriccano_unit,metriccano_unit*0.75,metriccano_unit/2])
                    metriccano_plate(6,4);
                // Fill the holes in the block that the flexure passes through
                translate([metriccano_unit*0.75,metriccano_unit*4.75,0])
                    cube([metriccano_unit*1.5,metriccano_unit,metriccano_unit]);
                translate([metriccano_unit*0.5,metriccano_unit*3.25,0])
                    cube([metriccano_unit*1.75,metriccano_unit,metriccano_unit]);
                translate([metriccano_unit*2.5,metriccano_unit*1.5,0])
                    cube([metriccano_unit*2,metriccano_unit*1.5,metriccano_unit]);
                // Version text
                translate([-metriccano_unit*1.5,metriccano_unit*2.25,metriccano_unit/2]) rotate([90,0,-90])
                    version_text();
            }
            // Slots for felxure beams. Take out slightly extra to stop bridges contacting
            translate([metriccano_unit*5.5,metriccano_unit*2.25,layer_height+1])
                cube([metriccano_unit*6,metriccano_unit,metriccano_unit],center=true);
            translate([metriccano_unit*1.5,metriccano_unit*6,layer_height+1])
                cube([metriccano_unit,metriccano_unit*6,metriccano_unit],center=true);
            // Nut sockets in the corners
            translate([0,metriccano_unit*0.75,metriccano_unit-m3_nut_height+0.001])
                m3_nut_cavity();
            translate([-metriccano_unit,metriccano_unit*0.75,metriccano_unit-m3_nut_height+0.001])
                m3_nut_cavity();
            translate([3*metriccano_unit,metriccano_unit*0.75,metriccano_unit-m3_nut_height+0.001])
                m3_nut_cavity();
            translate([4*metriccano_unit,metriccano_unit*0.75,metriccano_unit-m3_nut_height+0.001])
                m3_nut_cavity();
            translate([0,metriccano_unit*3.75,metriccano_unit-m3_nut_height+0.001])
                m3_nut_cavity();
            translate([-metriccano_unit,metriccano_unit*3.75,metriccano_unit-m3_nut_height+0.001])
                m3_nut_cavity();
            translate([3*metriccano_unit,metriccano_unit*3.75,metriccano_unit-m3_nut_height+0.001])
                m3_nut_cavity();
            translate([4*metriccano_unit,metriccano_unit*3.75,metriccano_unit-m3_nut_height+0.001])
                m3_nut_cavity();
        }

        // Side flexure modules
        translate([metriccano_unit,metriccano_unit*1.75,0]) joined_mettricano_2_via_flexures(5*metriccano_unit);
        translate([metriccano_unit*2,metriccano_unit*1.75,0])
            rotate([0,0,90]) joined_mettricano_2_via_flexures(5*metriccano_unit);
    }
    // Cut light well (a Metriccano unit-ish hole with rounded corners)
    well_size=metriccano_unit/2+0.5;
    translate([metriccano_unit*1.5,metriccano_unit*2.25,0])
        hull() {
            translate([well_size,well_size,0])
                cylinder(h=metriccano_unit*3,r=metriccano_screw_rad,$fn=20,center=true);
            translate([-well_size,well_size,0])
                cylinder(h=metriccano_unit*3,r=metriccano_screw_rad,$fn=20,center=true);
            translate([well_size,-well_size,0])
                cylinder(h=metriccano_unit*3,r=metriccano_screw_rad,$fn=20,center=true);
            translate([-well_size,-well_size,0])
                cylinder(h=metriccano_unit*3,r=metriccano_screw_rad,$fn=20,center=true);
        }
}

// 100mm long beam for testing flexure deflection with a 10g weight (.38 cal bullet)
test_pan_rad=10; // Radius of test pan cavity for weights
test_arm_len=100;
module test_flexure() {
    flexure_tab();
    // 100mm beam with pan on the end
    difference() {
        union() {
            translate([flexure_length/2,-4,0]) cube([100,8,8]);
            translate([flexure_length/2+test_arm_len,0]) cylinder(h=10,r=test_pan_rad+wall);
            // Wee spike on the end.
            translate([flexure_length/2+test_arm_len+test_pan_rad+wall-0.5,0,0.5])
                rotate([0,0,45]) cube([4,4,1],center=true);
        }
        // Scalop it out
        translate([flexure_length/2+test_arm_len,0,1]) cylinder(h=100,r=test_pan_rad);
    }
    // Anchor plate
    translate([-flexure_length/2-metriccano_unit*1.5,-metriccano_unit/2,0]) metriccano_plate(2,2);
}

// ** Testing Stuff**
// 100mm beam to test flexibility of a PLA flexure.
//test_flexure();
// Postioned plate under axis mechanism for try-fitting
//translate([-axis_drive_nut_x,0,-30])
//    axis_motor_pillar_assy();
//*****

// All the axis drive parts on one plate. Will also need a coupling from flexure_linear_coupling.scad
if (true) {
    translate([-60,-25,0]) flexure_linear_coupling();
    translate([10,10,0]) axis_complete();
    translate([-60,10,0]) axis_bearing_block();
    translate([15,-60,0]) axis_motor_pillar_assy();
    translate([-40,-65,0]) nema17_plate();
    translate([-10,-25,0]) metriccano_strip(2);    // Used to hold limit switch wires in place
}
