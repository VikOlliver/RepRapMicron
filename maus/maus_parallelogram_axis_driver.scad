// maus_axis_driver.scad - RepRapMicron motion stage
// (c)2025 vik@diamondage.co.nz, released under the terms of the GPL V3 or later
// Prototype Linear Maus Axis Diver, non-functional
// Tries to use a pantograph-like mechanism, paralleled up to provide stable
// drive, anchor, and effector ends.
// This contains much unsorted/unnecessary fluff.
//
// UNDER EARLY DEVELOPMENT

version_string="MAUS-L V0.00";

include <../library/m3_parts.scad>
include <../library/nema17lib.scad>
include <../library/metriccano.scad>

flexure_width=4;        // Reduced from original 7.
flexure_length=2.5;
flexure_height=1.0;     // Thickness of the flexure block including footings
flexure_thickness=0.6;  // Thickness of the actual flexure part
flexure_tab_length=flexure_length+2;    // Distance between two attachment zones.
vertical_flexure_length=8;
vertical_flexure_height=6;
vertical_flexure_width=8;   // Width of the anchor block
vertical_flexure_thick=8.2; // Width of the actual flexing bit

// Used to fiddle flexures. Just over one layer...
layer_height=0.21;
wall=2;                         // Arbitrary rigid wall thickness

reduction_ratio=0.5;    //  Amount we want to reduce the movement by

// Length of a parallelogram main arm
pll_main_arm_length=70;
pll_main_arm_at_45=sqrt(pll_main_arm_length*pll_main_arm_length/2);
pll_beam_end_flat_height=flexure_height+1.5;
pll_beam_x=8;  // Parallelogram beam width along the X axis
pll_beam_y=flexure_width+2;
pll_platform_beam_length=metriccano_unit;
// Bottom beam is higher than top beam as it has to fit between moving flexures
pll_top_beam_height=3;
pll_bottom_beam_height=10;
// Distance between the two most distant flexures
pll_flexure_to_flexure=pll_main_arm_at_45*2+flexure_tab_length+pll_platform_beam_length;

pll_arm_a_length=pll_main_arm_length*(1-reduction_ratio);
pll_arm_a_45=sqrt(pll_arm_a_length*pll_arm_a_length/2);
pll_arm_b_length=pll_main_arm_length*-reduction_ratio;
pll_arm_b_45=sqrt(pll_arm_b_length*pll_arm_b_length/2);

// Distance from frame center to frame center (leave gap so they dont rub).
pll_frame_centres=metriccano_nut_max_width+2;
// Calculate the gap between frames
pll_frame_spacing=pll_frame_centres-pll_beam_y;

// A flexure joint for printing it on the surface of the print bed. Footings extend 1mm.
// "flat" will print without an undercut
module flexure_tab(flat=false) difference() {
    translate([0,0,flexure_height/2]) cube([flexure_tab_length+2,flexure_width,flexure_height],center=true);
    if (flat) {
        // Hollow just the top of the flexure
        translate([0,0,flexure_height]) 
            cube([flexure_length*0.6,flexure_width*3,flexure_thickness*2],center=true);    
    } else {
        // Hollow the top of the flexure
        translate([0,0,flexure_height+layer_height]) 
            cube([flexure_length*0.6,flexure_width*3,flexure_thickness*2],center=true);    
        // Undercut the flexure so it does not touch print bed
        cube([flexure_length*0.6,flexure_width*3,layer_height*2],center=true);
    }
}

// A flexure join that will be printed suspended in air
module flexure_tab_unsupported() difference() {
    translate([0,0,flexure_height/2]) cube([flexure_tab_length+1,flexure_width,flexure_height],center=true);
    // Scalop the top of the flexure
    translate([0,0,flexure_height]) cube([flexure_length*0.6,flexure_width*3,flexure_height],center=true);
}

// Flat end of a beam, levelled on Z=0, centred on X=Y=0
// Made smaller for the top layer
module pll_beam_end(l=pll_beam_end_flat_height) {
    translate([-pll_beam_x/2,-pll_beam_y/2,0])
        cube([pll_beam_x,pll_beam_y,l]);
}

module pll_long_arm() {
    pll_beam_end();
    hull() {
        translate([0,0,pll_beam_end_flat_height]) pll_beam_end();
    translate([pll_main_arm_at_45,0,pll_main_arm_at_45]) pll_beam_end();
    }
}

module pll_arm_a() {
    pll_beam_end();
    hull() {
        translate([0,0,pll_beam_end_flat_height]) pll_beam_end();
    translate([pll_arm_a_45,0,pll_arm_a_45]) pll_beam_end();
    }
}

module pll_flexure_arm(x,y,reverse=false)  {
    // First flexure, placed on 0,0
    flexure_tab();
    if (reverse)
        translate([(pll_beam_x+flexure_tab_length)/2,0,0]) pll_beam_end();
    else
        translate([(-pll_beam_x-flexure_tab_length)/2,0,0]) pll_beam_end();
    // The beam bit
    hull() {
        if (reverse) {
            translate([(pll_beam_x+flexure_tab_length)/2,0,pll_beam_end_flat_height]) pll_beam_end();
            translate([x+(-pll_beam_x-flexure_tab_length)/2,0,y]) pll_beam_end(flexure_height);
        } else {
            translate([(-pll_beam_x-flexure_tab_length)/2,0,pll_beam_end_flat_height]) pll_beam_end();
            translate([x+(-pll_beam_x-flexure_tab_length)/2,0,y]) pll_beam_end(flexure_height);
        }
    }
    // Second flexure  placed on the mark
  
  translate([x,0,y]) flexure_tab(flat=true);
}

// Main arm wiht a kink where the centre flexure goes
module bent_pll_arm(ratio) {
    pll_flexure_arm(pll_main_arm_at_45*(1-ratio),pll_main_arm_at_45*(1-ratio),true);
    translate([pll_main_arm_at_45*(1-ratio),0,pll_main_arm_at_45*(1-ratio)])
        pll_flexure_arm(pll_main_arm_at_45*ratio,pll_main_arm_at_45*ratio);
}

// Pantograph arm with platforms in the middle and at each end
module centre_pll_arm() {
    // The -X arm
    bent_pll_arm(reduction_ratio) ;
    // The +X arm, with Arm B and beam platform on it.
    translate([pll_main_arm_at_45*2+pll_platform_beam_length+flexure_tab_length,0,0])
        rotate([0,0,180]) {
            // Main arm
            bent_pll_arm(1-reduction_ratio);
            // Arm B
            translate([pll_arm_b_45*2,0,0]) rotate([0,0,180])
                pll_flexure_arm(pll_arm_b_45,pll_arm_b_45,true);
            translate([pll_arm_b_45*2+(flexure_tab_length+pll_platform_beam_length)/2,0,pll_bottom_beam_height/2])
                cube([pll_platform_beam_length,pll_beam_y,pll_bottom_beam_height],center=true);
    }
            
    // Arm A
    translate([pll_arm_a_45*2,0,0]) rotate([0,0,180])
        pll_flexure_arm(pll_arm_a_45,pll_arm_a_45,true);
        
    // The top beam. Make sure it rests on top of the flexure...
    translate([pll_main_arm_at_45+pll_platform_beam_length/2+flexure_tab_length/2,0,pll_main_arm_at_45+pll_top_beam_height/2]) 
        cube([pll_platform_beam_length,flexure_width,pll_top_beam_height],center=true);
}

// Join the top beams.
translate([pll_flexure_to_flexure/2,
    0,pll_main_arm_at_45+metriccano_plate_height/2+pll_top_beam_height]) {
        // Start by linking the two outer ones.
       cube([pll_platform_beam_length,2*pll_frame_centres+flexure_width,metriccano_plate_height],center=true);
       // Now put a plate on the centre top beam.
        hull() {
           // This stops the slicer slicing the beam and the link to the centre simultaneously.
           translate([-pll_platform_beam_length,0,-metriccano_plate_height/4-2])
                cube([pll_platform_beam_length,flexure_width,2],center=true);
            // This bit sticks on the vertical face of the bridge
            translate([-pll_platform_beam_length/2,0,0])
                cube([2,flexure_width,metriccano_plate_height],center=true);
        }
}

// Tags to connect to flexures Heads off in -X, -Y and right end is at X=0.
module fixed_arm_flexure_tag() {
    // This bit goes on the flexure
    hull() {
        translate([1,(metriccano_unit-flexure_width*1.5)/2,flexure_height/2])
            cube([1,flexure_width,flexure_height],center=true);
        // This bit hides inside the metriccano strip
        translate([0.2-pll_platform_beam_length+flexure_tab_length/2+metriccano_screw_rad,0,metriccano_unit/4])
            cube([0.1,metriccano_unit/2,metriccano_unit/2],center=true);
    }
}

// Create an anchor for the end where the centre points is recessed
module anchor_pointed_in() translate([metriccano_unit/2,0,0]) {
    // Bevel this off for pivoting arm clearance
    translate([0,-metriccano_unit,0]) rotate([0,0,90])
        metriccano_strip(3,nutted=true);
    // Add a cavity for the drive nut
    translate([-metriccano_unit,0,0]) rotate([0,0,180]) metriccano_strip_flatend(1,nutted=true);
}

// An anchor where the centre flexure protrudes, aligned on X=0
// Anchor holes in -X direction
module anchor_pointed_out() union() {
     translate([-metriccano_unit*1.5,-metriccano_unit,0]) metriccano_strip(2,squared=true,nutted=true);    
     translate([-metriccano_unit*1.5,metriccano_unit,0]) metriccano_strip(2,squared=true,nutted=true);    
     translate([-metriccano_unit*1.5,0,0]) metriccano_strip(1,squared=true,nutted=true);    
 }


// Trio of pll frames
translate([0,pll_frame_centres,0]) centre_pll_arm();
translate([-pll_platform_beam_length,0,0]) centre_pll_arm();
translate([0,-pll_frame_centres,0]) centre_pll_arm();

// Join the bottom beams
translate([pll_arm_a_45*2+(flexure_tab_length)/2,0,0]) {
        translate([0,0,pll_bottom_beam_height-2])
         rotate([90,0,0]) rotate([0,0,30]) cylinder(h=pll_beam_y*3+pll_frame_spacing*2,r=4,center=true,$fn=3);
    // Lugs on the bottom beams
    translate([pll_platform_beam_length/2,-metriccano_unit*2,0]) rotate([0,0,-90]) metriccano_strip_flatend(1,nutted=true,extend_end=4.1);
    translate([pll_platform_beam_length/2,2*metriccano_unit,0]) rotate([0,0,90]) metriccano_strip_flatend(1,nutted=true,extend_end=4.5);
}

// Create a base to anchor the anchored end
translate([pll_flexure_to_flexure+flexure_tab_length/2,0,0]) {
    anchor_pointed_in();
}
// Anchor at X=0
translate([-flexure_tab_length/2,0,0]) anchor_pointed_out();

/*****************************************************************************
Code below is unused at this point.
*****************************************************************************/


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
limit_switch_level=22;    // Height to the top of the limit switch bar
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
                    // Chamfer to the top edge near the limit switch to ensure good backing to switch wires
                    // (rotation is a Wild-arsed guess)
                    translate([metriccano_unit/4,0,limit_switch_level/2]) rotate([0,-8,0])
                        translate([0,0,metriccano_unit])
                            cube([metriccano_unit*2,axis_arm_width,metriccano_unit*2],center=true);
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
