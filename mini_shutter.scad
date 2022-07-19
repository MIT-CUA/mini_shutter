//
// mini optical shutter for baseplate (1/2" beam height) using
// 4mm diameter coreless DC motor.
//
// motor is easily driven by current from digital output pin
// of RP2040 microcontroller

//-----------------------------------------------------------------------------
// global constants

use <util.scad>;

d_inch = 25.4;
pi = 3.14159;

$fa=0.5; // default minimum facet angle is now 0.5
$fs=0.1; // default minimum facet size is now 0.5 mm

screw_clear_dia_4_40 = 0.120 * d_inch;
screw_tap_dia_4_40   = 0.089 * d_inch;
screw_nut_dia_4_40   = 6.4;
screw_head_clear_dia_4_40 = 5.50;	// actually, pan screw head

screw_clear_dia_6_32 = 0.1450 * d_inch;
screw_tap_dia_6_32   = 0.1065 * d_inch;
screw_nut_dia_6_32   = 7.9;

screw_clear_dia_8_32 = 0.172 * d_inch;
screw_tap_dia_8_32   = 0.1360 * d_inch;
screw_nut_dia_8_32   = 8.7;		// measured from flat to flat
screw_head_clear_dia_8_32 = 7.00;	// hex
screw_washer_clear_dia_8_32 = 9.70;	// thorlabs 8-32 kit washer
screw_self_tap_dia_8_32 = screw_tap_dia_8_32 + 0.5;		// self-tapping for 8-32

// -----------------------------------------------------------------------------
// options


// -----------------------------------------------------------------------------
// mini 4mm coreless dc motor

module motor_4mm_coreless_dc(show=true, drill=false, theta=-45, drill_slot=true, mount_dia_extra=0){
     //
     // motor pointing up towards +z, positioned with bottom of cam
     // (closest side of cam to motor) at origin.  shaft has a cam on it.
     //
     // theta = angle of motor cam
     // drill_slot = include slot for motor housing clamp
     // 
     body_dz = 8.2;
     shaft_dia = 0.75;
     cam_outer_dia = 4.0;
     cam_dz = 2.5;
     cam_shaft_dia = 1.5;
     cam_yoff = -0.1;
     oal = 11.4;				// overall length
     slot_dy = 0.5;
     slot_dx = 8;
     module cam(show=true, drill=false){
	  color("blue"){
	       cylinder(d=cam_shaft_dia, h=cam_dz + (drill ? 1 : 0) );	// cam center - on shaft
	       difference(){
		    union(){
			 cylinder(d1=cam_outer_dia + (drill ? 0.4 : 0),	// compensate for burr on print plate
				  d2=cam_outer_dia + (drill ? 0.1 : 0),
				  h=0.4);
			 cylinder(d=cam_outer_dia + (drill ? 0.1 : 0),
				  h=cam_dz + (drill ? 1 : 0));
		    }
		    translate([-5, -10 + cam_yoff, -1])
			 color("red") cube([10, 10, 10]);
	       }
	  }
     }
     union(){
	  extra_dz = (drill ? 8 : 0);		// extra tube length when drilling, for wires to exit
	  extra_dia = mount_dia_extra;		// possibly different diameter when drilling, so motor fits snugly in motor housing
	  translate([0, 0, -oal + cam_dz]){
	       translate([0, 0, -extra_dz]) color("silver"){
		    scale([1 + (drill ? 0.1 : 0), 1, 1])	// for holder, compensate for underhang from top when printing
			 cylinder(d=4 + extra_dia, h=body_dz + extra_dz);	// main cylindrical body of motor
		    if (drill && drill_slot){
			 // cut slot along side of motor, so the motor housing can hold motor with natural spring clamp action
			 translate([-slot_dx, -slot_dy/2, 0])
			      cube([slot_dx, slot_dy, body_dz + extra_dz]);
		    }
	       }
	       translate([0, 0, 0.01]) color("black") cylinder(d=cam_shaft_dia, h=oal-0.01);	// motor shaft
	  }
	  rotate([0, 0, theta])
	       cam(show=show, drill=drill);		// cam at end of shaft
     }
}

// -----------------------------------------------------------------------------
// c05g mount onto baseplate

module baseplate_mount_holes(slen=5){
     //
     // holes for mounting onto baseplate: 8-32 screw and two 2mm pins,
     // compatible with footprint of thorlabs c05 polaris mirror mount.
     //
     // slen = screw length (dz before screw head)
     //
     pin_dia = 2.0;
     pin_dy = 5.0;
     pin_dz = 2.2;
     cylinder(d=screw_clear_dia_8_32, h=20);
     translate([0, 0, slen]){
	  cylinder(d=screw_head_clear_dia_8_32, h=20);
     }
     translate([0, 0, -0.01])
	  cylinder(d1=screw_clear_dia_8_32 + 0.4, d2=screw_clear_dia_8_32, h=0.5);	// taper to compensate for print bed lip
     for(dy=[-1,1]){
	  translate([0, dy*pin_dy, 0]){
	       cylinder(d=pin_dia+0.1, h=pin_dz);
	       translate([0, 0, -0.01])
		    cylinder(d1=pin_dia + 0.4, d2=pin_dia + 0.1, h=0.4);	// taper to compensate for print bed lip
	  }
     }
}

// -----------------------------------------------------------------------------
// controller electronics

module controller_pcb(show=true, drill=false, holes=false){
     // PCB in XY plane with origin on bottom side at y-midpoint along board edge
     // pointing along -x direction
     pcb_dx = 29.2;
     pcb_dy = 40.35;
     pcb_thick = 2;

     mount_screw_dia = 1.25;
     mount_screw_head_dia = 5;

     if (show){
	  rotate([0, 0, 90])
	       translate([-pcb_dx/2, -pcb_dy*0, 0])
	       import("electronics/mini_shutter_driver v1.stl");
     }

     module mounting_holes(zoff=0){
	  for(xy=[ [-3.83, 9.5], [-25.4, 9.5+2.54] ]){
	       translate([xy[0], xy[1], zoff])
		    children();
	       }
     }

     if (drill){
	  if (1){
	       slot_width = pcb_dx + 1.5;
	       translate([ -pcb_dy, -slot_width/2, 0]){
		    color("pink"){
			 cube([pcb_dy, slot_width, pcb_thick]);			// PCB
		    }
		    color("orange"){					// components on PCB
			 rim = 1.2;
			 comp_thick = 7;
			 translate([-rim, rim, -0.01])
			      cube([pcb_dy, pcb_dx-2*rim, comp_thick]);		// top-side components
		    }
		    difference(){
			 color("brown"){					// bottom-side components on PCB
			      rim = 1.2;
			      comp_thick = 3;
			      translate([-rim, rim, -comp_thick])
				   cube([pcb_dy, pcb_dx-2*rim, comp_thick]);		// bottom-side components
			 }
			 color("red"){
			      translate([ pcb_dy, slot_width/2, -3]){
				   mounting_holes(){
					cylinder(d1=6, d2=4, h=3);		// feet for mounting screws
				   }
			      }
			 }
		    }
	       }
	  }
	  color("red"){
	       mounting_holes(zoff=-10)
		    cylinder(d=mount_screw_dia, h=20);		// screw holes
	       mounting_holes(zoff=0)
		    cylinder(d=mount_screw_head_dia, h=20);		// screw head holes
	  }
     }

     if (holes){
	  mounting_holes();
     }
}

module electronics_mount(show=true, show_bottom=false, show_electronics=false){
     //
     // mount for control electronics PCB, oriented in lab frame (of final optical shutter).
     // holds PCB from outer rim, to allow space for components (on both sides of PCB),
     // including the RP2040 module.
     // Open at top for USB-C connector
     // Open at front for push-buttons
     //
     // if show_bottom then make rectangle for bottom of mount (for hull to something else)
     //
     mount_dy = 35;
     mount_dx = 8;
     mount_dz = 40 - 9;
     mount_xoff = -2;
     pcb_zoff = 3;

     module epos(){
	  translate([0, 0, pcb_zoff])
	       rotate([0, 90, 0])
	       children();
     }

     module bottom(){
	  translate([-mount_dx/2, -mount_dy/2, 0])
	       cube([mount_dx, mount_dy, 0.1]);
     }

     if (show){
	  difference(){
	       sr_zoff = 24 - 4;	// strain relief z-offset
	       sr_yoff = 3;
	       sr_od = mount_dx-1;
	       sr_id = 4;
	       sr_dz = 3;
	       union(){
		    translate([-mount_dx/2, -mount_dy/2, 0])
			 color("blue")
			 cube([mount_dx, mount_dy, mount_dz]);
		    difference(){
			 hull(){
			      translate([0, mount_dy/2 + sr_yoff, sr_zoff])
				   cylinder(d=sr_od, h=sr_dz);
			      translate([0, 0, sr_zoff-sr_dz - 3])
				   bottom();
			 }
			 translate([0, mount_dy/2 + sr_yoff, sr_zoff-10])
			      color("red")
			      cylinder(d=sr_id, h=20);
		    }
	       }
	       epos()
		    controller_pcb(show=false, drill=true);
	  }
     }
     if (show_bottom){
	  bottom();
     }
     if (show_electronics){
	  epos()
	       controller_pcb(show=true, drill=false);
     }
}

// -----------------------------------------------------------------------------
// shutter with mount

module mini_shutter(dz=12.7, show_mount=true, show_motor=true, show_blade=true,
		    drill=false, openclose=0, include_emount=true,
		    show_electronics=false, do_mirror=1){
     //
     // beam goes along +x, at z=0
     // optical center is center of shutter hole for beam
     // base is dz below beam hight
     //
     // openclose = fraction from open (=0) to close (=1)
     // do_mirror = 1 if motor should be put on the +y side (instead of on the -y side)
     //             The +y side is the side closer to the RP2040's terminals for the motor
     //
     base_dx = 10;
     base_dy = 15.2;
     base_dz = 4;
     motor_housing_dia = 6.5;
     mhd_dz = 8 - 3;
     mhd_xoff = -0.85;
     motor_zoff = 0;
     motor_yoff = (do_mirror ? -1 : 1) * (-6 - 1);		// how far motor axis is away from the optical axis
     motor_xoff = -1;
     motor_theta = -45 - 20;				// angle of motor cam shaft
     base_xoff = -7;
     beam_clear_dia = 4 + 1;

     theta_closed = 0 + 4 + 5 + 12;		// angle at which shutter is opened (closed if not mirrored)
     theta_opened = -52 - 4 - 10 + 10 + 4;	// angle at which shutter is closed (opened if not mirrored)
     theta = (openclose ? theta_opened : theta_closed);

     shutter_zoff = 0.2;
     shutter_center_thick = 2.6;
     shutter_center_dia = 6;
     shutter_blade_thick = 0.5;
     shutter_blade_yoff = 6;
     shutter_blade_dia = 5 + 2;		// diameter of circle blocking laser
     shutter_blade_dtheta = 110 + 20;	// angle between the two blades of the shutter 

     endstop_angle = -80 - 20 + 5 + 9 + 5;	// angle in lab frame where endstop should be placed, with 0 - beam, -90 = baseplate
     endstop_yoff = 5 + 2 + 1 + 0.1;	// offset in motor frame, froom motor axis (this is in the z-direction in the lab frame)
     endstop_zoff = -2;		// z offset of endstop rectangle, in motor frame
     endstop_len = 5 - 2;		// z-height of endstop rectangle
     endstop_wid = 7 - 2 + 1 - 2;	// in the lab frame, size along y-axis (transverse to laser beam)
     endstop_height = 5 - 1;	// actually its thickness

     module motor_position(){
	  // move children to position (and orientation) of motor on the mini shutter
	  // motor is initially along +z
	  // on the mini shutter, the motor is along +x
	  translate([motor_xoff, motor_yoff, motor_zoff])
	       rotate([0, 90, 0])
	       children();
     }

     module shutter_blade(dtheta=90, cutout_cam=true){
	  // fits onto motor cam and blocks (or allows through) the optical beam.
	  // has two arms: one which hits endstop when closed, and the other which
	  // blocks the beam and also hits the endstop when open.
	  //
	  // given in frame of motor.
	  // designed to be glued onto the motor's cam.
	  
	  module one_blade(){
	       translate([0, 0, shutter_zoff]){
		    hull(){
			 cylinder(d=shutter_center_dia, h=shutter_center_thick);
			 translate([0, shutter_blade_yoff, 0]) 
			      cylinder(d=shutter_blade_dia, h=shutter_blade_thick);
		    }
	       }
	  }

	  if (1){
	       difference(){
		    for(th=[0, -dtheta]){
			 rotate([0, 0, th]) one_blade();
		    }
		    if (cutout_cam){
			 motor_4mm_coreless_dc(show=false, drill=true, theta=motor_theta);	// cut out motor cam
		    }
	       }
	  }
     }

     module electronics_position(){
	  //
	  // move mount for electronics to final position in lab frame
	  //
	  emount_zoff = 6;
	  emount_xoff = -14;
	  translate([emount_xoff, 0, emount_zoff]) children();
     }

     difference(){
	  union(){
	       if (show_mount){
		    difference(){
			 color("orange"){
			      hull(){
				   translate([-base_dx/2 + base_xoff, -base_dy/2, -dz])
					cube([base_dx, base_dy, base_dz]);		// cube for base
				   motor_position()
					translate([0, 0, -mhd_dz+mhd_xoff]) cylinder(d=motor_housing_dia, h=mhd_dz);
			      }
			 }
			 motor_position()
			      motor_4mm_coreless_dc(show=false, drill=true, theta=motor_theta);	// hole where motor goes
		    }
		    difference(){
			 color("skyblue"){
			      hull(){
				   translate([-base_dx/2 + base_xoff, -base_dy/2, -dz + base_dz])
					cube([base_dx, base_dy, 0.1]);		// cube for base
				   electronics_position(){
					electronics_mount(show=false, show_bottom=true);
				   }
			      }
			      electronics_position(){
				   electronics_mount(show=true, show_bottom=false);
			      }
			 }
			 motor_position()
			      motor_4mm_coreless_dc(show=false, drill=true, drill_slot=false, theta=motor_theta, mount_dia_extra=1);	// hole where motor goes, no slot
		    }
		    color("brown"){	// endstop
			 hull(){
			      base_slice_dy = 5;
			      motor_position(){
				   rotate([0, 0, endstop_angle])
					translate([0, endstop_yoff, endstop_zoff])
					translate([-endstop_wid/2, 0, 0])
					cube_with_rounded_corners([endstop_wid, endstop_len, endstop_height], dia=3);	// endstop cube
			      }
			      translate([-base_dx/2 + base_xoff, -base_dy/2, -dz])
				   // cube([base_dx, base_dy, 0.1]);		// thin base for hull
				   translate([0, base_dy-base_slice_dy, 0])
				   cube([base_dx, base_slice_dy, 0.1]);		// thin base for hull
			 }
		    }
	       }
	  }
	  color("red"){
	       translate([base_xoff, 0, -dz-0.1])
		    baseplate_mount_holes();				// holes for 8-32 screw and 2mm pins
	       rotate([0, 90, 0])					// clearance tube for optical beam
		    translate([0, 0, -30])
		    cylinder(d=beam_clear_dia, h=60);
	  }
	  // cut out endstop based on two positions of the shutter blade
	  color("purple"){
	       for (th=[theta_closed + 2, theta_opened - 2]){
		    motor_position()
			 rotate([0, 0, th])
			 shutter_blade(shutter_blade_dtheta, cutout_cam=false);
	       }
	  }
     }

     if (show_electronics){
	  electronics_position(){
	       electronics_mount(show=false, show_bottom=false, show_electronics=true);
	  }
     }

     if (show_blade){
	  color("green"){
	       motor_position()
		    rotate([0, 0, theta])
		    shutter_blade(shutter_blade_dtheta);
	  }
     }
     if (show_motor){
	  motor_position()
	       motor_4mm_coreless_dc(show=true, drill=false, theta=theta+motor_theta);
     }
}

//-----------------------------------------------------------------------------

module print_blade(){
     rotate([0, -90, 0])
	  mini_shutter(show_mount=false, show_motor=false, show_blade=true, openclose=0);
}
     
module animation_full_model(){
     openclose = $t;
     mini_shutter(show_mount=true, show_motor=true, show_blade=true, openclose=openclose);     
}

//-----------------------------------------------------------------------------

// motor_4mm_coreless_dc();
// mini_shutter(show_mount=true, show_motor=true, show_blade=true);
// mini_shutter(show_mount=true, show_motor=true, show_blade=true, openclose=0);
// mini_shutter(show_mount=true, show_motor=true, show_blade=false, openclose=0);

// mini_shutter(show_mount=true, show_motor=true, show_blade=true, openclose=1);
// mini_shutter(show_mount=true, show_motor=true, show_blade=true, openclose=0);
mini_shutter(show_mount=true, show_motor=true, show_blade=true, openclose=0, show_electronics=true);

// mini_shutter(show_mount=false, show_motor=false, show_blade=true, openclose=0);			// for showing just blade
// mini_shutter(show_mount=true, show_motor=false, show_blade=false, openclose=0);		// for printing mount

// print_blade();

// animation_full_model();

// controller_pcb(show=true, drill=false);
// controller_pcb(show=true, drill=true);

// electronics_mount(show=true);
// electronics_mount(show=false, show_bottom=true);
