//
// camera shutter used as an optical shutter
//

//-----------------------------------------------------------------------------
// global constants

use<util.scad>;

d_inch = 25.4;
pi = 3.14159;

$fa = 0.5; // default minimum facet angle is now 0.5
$fs = 0.1; // default minimum facet size is now 0.5 mm

screw_clear_dia_4_40 = 0.120 * d_inch;
screw_tap_dia_4_40 = 0.089 * d_inch;
screw_nut_dia_4_40 = 6.4;
screw_head_clear_dia_4_40 = 5.50; // actually, pan screw head

screw_clear_dia_6_32 = 0.1450 * d_inch;
screw_tap_dia_6_32 = 0.1065 * d_inch;
screw_nut_dia_6_32 = 7.9;

screw_clear_dia_8_32 = 0.172 * d_inch;
screw_tap_dia_8_32 = 0.1360 * d_inch;
screw_nut_dia_8_32 = 8.7;           // measured from flat to flat
screw_head_clear_dia_8_32 = 7.00;   // hex
screw_washer_clear_dia_8_32 = 9.70; // thorlabs 8-32 kit washer
screw_self_tap_dia_8_32 = screw_tap_dia_8_32 + 0.5; // self-tapping for 8-32

pcb_global_z_offset = -5.0;

//-----------------------------------------------------------------------------
// camera shutter model

module cots_dc5v_camera_shutter(show = true, drill = false) {
    //
    // Uses "DC 5V Digital Camera Shutter Micro Rotating electromagnet Control
    // Switch" from ebay:
    // https://www.ebay.com/itm/124456754185?hash=item1cfa335c09:g:8tIAAOSwq4Nh7qDp
    //
    // oriented with shutter in yz plane, optical axis along x, magnet housing
    // pointing to +x and sitting above shutter.
    //
    // origin in middle of aperture
    //
    cs_dy = 8.5 + (drill ? 0.2 : 0);
    cs_dz = 17.9;
    cs_magnet_dx = 8.6;
    cs_magnet_zoff = 15.5;
    cs_magnet_dia = 6.2;
    cs_bot_stub_dy = 1.5 + (drill ? 0.4 : 0);
    cs_bot_stub_dz = 0.7 + (drill ? 0.2 : 0);
    cs_bot_dx = 4.65; // includes leads to electromagnet on bottom
    cs_dx = 4.75;     // midpoint including funnel to aperture
    // cs_aperture_dia = 6.36;
    cs_aperture_dia = 4.5;
    cs_aperture_zpos = 8.8; // distance from bottom (above stub)
    cs_bot_strut_hole_dia = 1.5 + (drill ? 0.5 : 0);
    cs_bot_strut_dx = 3.4;                      // length from back surface
    cs_bot_strut_dy = 1.2 + (drill ? 0.17 : 0); // thickness
    cs_bot_strut_dz = 3.0;
    cs_bot_strut_hole_zpos = (cs_bot_strut_dz - cs_bot_strut_hole_dia) / 2 +
                             cs_bot_strut_hole_dia / 2;
    cs_bot_strut_hole_xpos =
        -cs_dx / 2 - cs_bot_strut_dx + cs_bot_strut_hole_zpos;

    bot_pin_dz = 1.2;
    bot_pin_dx = 1.2 + (drill ? 0.3 : 0);
    bot_pin_dy = 1.5 + (drill ? 0.1 : 0);
    bot_pin_zoff = 2.8 - bot_pin_dz;
    bot_pin_xoff = 2.3 - bot_pin_dx + (drill ? 0.15 : 0);

    up_strut_dx = 3.4;
    up_strut_dy = 1.2 + (drill ? 0.1 : 0);
    up_strut_dz = 3.0;
    up_strut_hole_dia = 1.5 + (drill ? 0.3 : 0);
    up_strut_zpos = 5 - up_strut_dz;
    up_strut_hole_zpos = up_strut_zpos + up_strut_dz / 2;
    up_strut_hole_xpos = cs_dx / 2 + up_strut_dx - up_strut_dz / 2;

    cut_bot_strut_dx = cs_bot_strut_dx + (drill ? 0.2 : 0);
    cut_up_strut_dx = up_strut_dx + (drill ? 0.2 : 0);

    screw_clear_head_dia_1_7mm = 3.1 + 0.4; // head diameter for 1.7mm screw

    bot_mag_cut_dx = 20;
    bot_mag_cut_dz = 20;
    bot_mag_cut_dy = 7;
    bot_mag_cut_zoff = 2;

    bot_front_cut_dx = 6;

    module holes() {
        screw_head_yoff = cs_dy / 2 + 2;
        color("red") {
            translate([ 0, 0, cs_aperture_zpos ]) rotate([ 0, 90, 0 ])
                translate([ 0, 0, -10 ])
                    cylinder(d = cs_aperture_dia,
                             h = 20); // main aperture for optical beam path
            translate([ cs_bot_strut_hole_xpos, 0, cs_bot_strut_hole_zpos ]) {
                rotate([ 90, 0, 0 ]) {
                    translate([ 0, 0, -10 ]) cylinder(
                        d = cs_bot_strut_hole_dia, h = 20); // bottom strut hole
                    translate([ 0, 0, screw_head_yoff ]) cylinder(
                        d = screw_clear_head_dia_1_7mm, h = 20); // screw head
                }
            }
            translate([ up_strut_hole_xpos, 0, up_strut_hole_zpos ]) {
                rotate([ 90, 0, 0 ]) {
                    translate([ 0, 0, -10 ]) cylinder(d = up_strut_hole_dia,
                                                      h = 20); // up strut hole
                    translate([ 0, 0, screw_head_yoff ]) cylinder(
                        d = screw_clear_head_dia_1_7mm, h = 20); // screw head
                }
            }
        }
    }

    translate([ 0, 0, -cs_aperture_zpos ]) {
        difference() {
            union() {
                cut_dx = cs_dx + (drill ? 0.2 : 0);
                color("silver") translate([ -cut_dx / 2, -cs_dy / 2, 0 ])
                    cube([ cut_dx, cs_dy, cs_dz ]);
                color("gray") translate([
                    -cut_dx / 2, -cs_bot_stub_dy + cs_dy / 2,
                    -cs_bot_stub_dz + 0.01
                ]) // stub on bottom right
                    cube([ cut_dx, cs_bot_stub_dy, cs_bot_stub_dz ]);
                color("black") translate([
                    -cut_bot_strut_dx - cs_dx / 2, -cs_dy / 2, 0
                ]) // strut bottom left back
                    cube(
                        [ cut_bot_strut_dx, cs_bot_strut_dy, cs_bot_strut_dz ]);
                color("black") translate([
                    cs_dx / 2, -cs_dy / 2,
                    up_strut_zpos
                ]) // strut upper left front
                    cube([ cut_up_strut_dx, up_strut_dy, up_strut_dz ]);
                color("black") translate([
                    -cs_dx / 2 + bot_pin_xoff, -cs_dy / 2 - bot_pin_dy,
                    bot_pin_zoff
                ]) // bottom pin
                    cube([ bot_pin_dx, bot_pin_dy, bot_pin_dz ]);
                color("green") translate(
                    [ -cs_dx / 2, 0, cs_magnet_zoff ]) // magnet cylinder
                    rotate([ 0, 90, 0 ])
                        cylinder(d = cs_magnet_dia, h = cs_magnet_dx);
            }
            holes();
        }
        if (drill) {
            color("pink") {
                translate([ cs_dx / 2, -cs_dy / 2, 0 ]) // slot for up strut
                    cube([ cut_up_strut_dx, up_strut_dy, up_strut_zpos + 14 ]);
                translate([
                    -cut_bot_strut_dx - cs_dx / 2, -cs_dy / 2, 0
                ]) // slot for bot strut
                    cube([
                        cut_bot_strut_dx, cs_bot_strut_dy, cs_bot_strut_dz + 10
                    ]);
                translate([
                    -cs_dx / 2 + bot_pin_xoff, -cs_dy / 2 - bot_pin_dy + 0.01, 0
                ]) // bottom pin
                    cube([ bot_pin_dx, bot_pin_dy, 16 ]);
                translate([
                    -cs_dx / 2, -bot_mag_cut_dy / 2,
                    bot_mag_cut_zoff
                ]) // cutout to access bottom magnet pins
                    cube([ bot_mag_cut_dx, bot_mag_cut_dy, bot_mag_cut_dz ]);
                translate([
                    -bot_front_cut_dx, -bot_mag_cut_dy / 2,
                    bot_mag_cut_zoff
                ]) // cutout for bottom front
                    cube([ bot_front_cut_dx, bot_mag_cut_dy, bot_mag_cut_dz ]);
            }
            holes();
        }
    }
}

// -----------------------------------------------------------------------------
// c05g mount onto baseplate

module baseplate_mount_holes(slen = 5) {
    //
    // holes for mounting onto baseplate: 8-32 screw and two 2mm pins,
    // compatible with footprint of thorlabs c05 polaris mirror mount.
    //
    // slen = screw length (dz before screw head)
    //
    pin_dia = 2.0;
    pin_dy = 5.0;
    pin_dz = 2.2;
    cylinder(d = screw_clear_dia_8_32, h = 20 - 6);
    translate([ 0, 0, slen ]) {
        cylinder(d = screw_head_clear_dia_8_32, h = 20 - 8);
    }
    translate([ 0, 0, -0.01 ])
        cylinder(d1 = screw_clear_dia_8_32 + 0.4, d2 = screw_clear_dia_8_32,
                 h = 0.5); // taper to compensate for print bed lip
    for (dy = [ -1, 1 ]) {
        translate([ 0, dy * pin_dy, 0 ]) {
            cylinder(d = pin_dia + 0.1, h = pin_dz);
            translate([ 0, 0, -0.01 ])
                cylinder(d1 = pin_dia + 0.4, d2 = pin_dia + 0.1,
                         h = 0.4); // taper to compensate for print bed lip
        }
    }
}

// -----------------------------------------------------------------------------
// controller electronics

module controller_pcb(show = true, drill = false, holes = false) {
    // PCB in XY plane with origin on bottom side at y-midpoint along board edge
    // pointing along -x direction
    pcb_dx = 29.2;
    pcb_dy = 40.35;
    pcb_thick = 2;

    mount_screw_dia = 1.25;
    mount_screw_head_dia = 5;

    if (show) {
        rotate([ 0, 0, 90 ]) translate([ -pcb_dx / 2, -pcb_dy * 0, 0 ])
            import("electronics/mini_shutter_driver v1.stl");
    }

    module mounting_holes(zoff = 0) {
        for (xy = [ [ -3.83, 9.5 ], [ -25.4, 9.5 + 2.54 ] ]) {
            translate([ xy[0], xy[1], zoff ]) children();
        }
    }

    if (drill) {
        if (1) {
            slot_width = pcb_dx + 1.5;
            translate([ -pcb_dy, -slot_width / 2, 0 ]) {
                color("pink") {
                    cube([ pcb_dy, slot_width, pcb_thick ]); // PCB
                }
                color("orange") { // components on PCB
                    rim = 1.2;
                    comp_thick = 7;
                    translate([ -rim, rim, -0.01 ]) cube([
                        pcb_dy, pcb_dx - 2 * rim,
                        comp_thick
                    ]); // top-side components
                }
                difference() {
                    color("brown") { // bottom-side components on PCB
                        rim = 1.2;
                        comp_thick = 3;
                        translate([ -rim, rim, -comp_thick ]) cube([
                            pcb_dy, pcb_dx - 2 * rim,
                            comp_thick
                        ]); // bottom-side components
                    }
                    color("red") {
                        translate([ pcb_dy, slot_width / 2, -3 ]) {
                            mounting_holes() {
                                cylinder(d1 = 6, d2 = 4,
                                         h = 3); // feet for mounting screws
                            }
                        }
                    }
                }
            }
        }
        color("red") {
            mounting_holes(zoff = -10)
                cylinder(d = mount_screw_dia, h = 20); // screw holes
            mounting_holes(zoff = 0)
                cylinder(d = mount_screw_head_dia, h = 20); // screw head holes
        }
    }

    if (holes) {
        mounting_holes();
    }
}

module electronics_mount(show = true, show_bottom = false,
                         show_electronics = false) {
    //
    // mount for control electronics PCB, oriented in lab frame (of final
    // optical shutter). holds PCB from outer rim, to allow space for components
    // (on both sides of PCB), including the RP2040 module. Open at top for
    // USB-C connector Open at front for push-buttons
    //
    // if show_bottom then make rectangle for bottom of mount (for hull to
    // something else)
    //
    mount_dy = 35;
    mount_dx = 8;
    mount_dz = 40 - 9;
    mount_xoff = -2;
    pcb_zoff = 3;

    module epos() {
        translate([ 0, 0, pcb_zoff + pcb_global_z_offset ]) rotate([ 0, 90, 0 ]) children();
    }

    module bottom() {
        mirror([ 0, 1, 0 ]) {
            translate([ -mount_dx / 2, -mount_dy / 2, 0 ])
                cube([ mount_dx, mount_dy * 0.55, 0.1 ]);
        }
    }

    if (show) {
        difference() {
            sr_zoff = 24 - 4; // strain relief z-offset
            sr_yoff = 3;
            sr_od = mount_dx - 1;
            sr_id = 4;
            sr_dz = 3;
            union() {
                translate([ -mount_dx / 2, -mount_dy / 2, 0 ]) color("blue")
                    cube([ mount_dx, mount_dy, mount_dz ]);
                difference() {
                    hull() {
                        translate([ 0, mount_dy / 2 + sr_yoff, sr_zoff ])
                            cylinder(d = sr_od, h = sr_dz);
                        translate([ 0, 0, sr_zoff - sr_dz - 3 ]) bottom();
                    }
                    translate([ 0, mount_dy / 2 + sr_yoff, sr_zoff - 10 ])
                        color("red") cylinder(d = sr_id, h = 20);
                }
            }
            epos() controller_pcb(show = false, drill = true);
        }
    }
    if (show_bottom) {
        bottom();
    }
    if (show_electronics) {
        epos() controller_pcb(show = true, drill = false);
    }
}

//-----------------------------------------------------------------------------

module camera_shutter(dz = 12.7, show_mount = true, show_electronics = true,
                      include_electronics_mount = true) {
    //
    // beam goes along +x, at z=0
    // optical center is center of shutter hole for beam
    // base is dz below beam hight
    //
    base_dx = 10;
    base_dy = 15.2;
    base_dz = 4;
    base_xoff = 8 - 1;
    cs_housing_dx = 13.4;
    cs_housing_dy = 12.5;
    cs_housing_dz = 9;
    cs_housing_zoff = -cs_housing_dz + 0;
    cs_housing_xoff = 0;

    elec_standoff_dia = 5;
    elec_standoff_dz = 4;
    elec_standoff_zoff = 6 - 1;
    elec_standoff_xoff = 9 + 0.5;
    elec_standoff_yoff = 6;

    optical_beam_dia = 4.6;

    module cs_position() { rotate([ 0, 0, 180 ]) children(); }

    module electronics_position() {
        //
        // move mount for electronics to final position in lab frame
        //
        emount_zoff = 12 + elec_standoff_dz;
        emount_xoff = base_xoff + elec_standoff_xoff - 6;
        translate([ emount_xoff, 0, emount_zoff ]) children();
    }

    difference() {
        union() {
            color("orange") {
                hull() {
                    translate([ -base_dx / 2 + base_xoff, -base_dy / 2, -dz ])
                        cube([ base_dx, base_dy, base_dz ]); // cube for base
                    translate([
                        -cs_housing_dx / 2 + cs_housing_xoff,
                        -cs_housing_dy / 2,
                        cs_housing_zoff
                    ])
                        cube([
                            cs_housing_dx, cs_housing_dy,
                            cs_housing_dz
                        ]); // housing for DC solenoid camera shutter
                }
            }
            if (include_electronics_mount) {
                color("blue") {
                    difference() {
                        union() {
                            // electronics mount
                            elec_base_dx = 3;
                            elec_base_dy = 4;
                            for (m = [ 0, 1 ]) {
                                mirror([ 0, m, 0 ]) {
                                    hull() {
                                        translate([
                                            -elec_base_dx / 2 + base_xoff,
                                            -elec_base_dy + base_dy / 2, -dz +
                                            base_dz
                                        ])
                                            cube([
                                                elec_base_dx, elec_base_dy, 0.1
                                            ]); // cube for base
                                        translate([
                                            elec_standoff_xoff, elec_standoff_yoff,
                                            elec_standoff_zoff
                                        ]) cylinder(d = elec_standoff_dia, h = 0.1);
                                    }
                                }
                            }
                            for (m = [ 0, 1 ]) {
                                mirror([ 0, m, 0 ]) {
                                    translate([
                                        elec_standoff_xoff, elec_standoff_yoff,
                                        elec_standoff_zoff
                                    ]) cylinder(d = elec_standoff_dia,
                                                h = elec_standoff_dz);
                                }
                            }
                            for (m = [ 0, 1 ]) {
                                mirror([ 0, m, 0 ]) {
                                    hull() {
                                        translate([
                                            elec_standoff_xoff, elec_standoff_yoff,
                                            elec_standoff_zoff +
                                                elec_standoff_dz * 0
                                        ]) cylinder(d = elec_standoff_dia, h = 0.1);
                                        electronics_position() {
                                            electronics_mount(show = false,
                                                              show_bottom = true);
                                        }
                                    }
                                }
                            }
                            electronics_position() {
                                electronics_mount(show = true, show_bottom = false);
                            }
                        }
                        translate([10.5, 0, 19 + pcb_global_z_offset]) {
                            rotate([0, 90, 0]) {
                                controller_pcb(show = false, drill = true);
                            }
                        }
                    }
                }
            }
        }
        cs_position() { cots_dc5v_camera_shutter(drill = true); }
        color("red") {
            translate([ base_xoff, 0, -dz - 0.1 ])
                baseplate_mount_holes(); // holes for 8-32 screw and 2mm pins
        }
        color("green") { // main optical beam
            rotate([ 0, 90, 0 ]) translate([ 0, 0, -20 ])
                cylinder(d = optical_beam_dia,
                         h = 40); // main aperture for optical beam path
        }
    }
    if (show_mount) {
        cs_position() { cots_dc5v_camera_shutter(show = true, drill = false); }
    }
}

//-----------------------------------------------------------------------------

// cots_dc5v_camera_shutter(drill=true);
// camera_shutter(show_mount=true);
camera_shutter(show_mount = false);
// camera_shutter(show_mount=false, include_electronics_mount=false);
// camera_shutter(show_mount=true, include_electronics_mount=false);
