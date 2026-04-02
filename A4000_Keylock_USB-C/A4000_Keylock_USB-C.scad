// Replace the A4000D front key lock with a USB-C port
// Thread: M12x1.0
// e.g. for KickSmash32

eps = 1/128;
$fn = 256;
//body_color = grey(40);
body_color = grey(90);
function r2sides(r) = $fn ? $fn : ceil(max(min(360 / $fa, r * 2 * PI / $fs), 5));
function r2sides4n(r) = floor((r2sides(r) + 3) / 4) * 4;
function grey(n) = [0.01, 0.01, 0.01] * n;
function reverse(v) = let(n = len(v) - 1) [for(i = [0 : n]) v[n - i]];
function unit(v) = let(n = norm(v)) n ? v / n : v;
function vec3(v) = [v.x, v.y, v.z];
function transform(v, m) = vec3(m * [v.x, v.y, v.z, 1]);
function transform_points(path, m) = [for(p = path) transform(p, m)];

function rotate_m(a) =
    let(av = is_list(a) ? a : [0, 0, a],
        cx = cos(av[0]), cy = cos(av[1]), cz = cos(av[2]),
        sx = sin(av[0]), sy = sin(av[1]), sz = sin(av[2]))
        [[ cy*cz, sx*sy*cz - cx*sz, cx*sy*cz + sx*sz, 0],
         [ cy*sz, sx*sy*sz + cx*cz, cx*sy*sz - sx*cz, 0],
         [-sy,    sx*cy,            cx*cy,             0],
         [ 0,     0,                0,                 1]];

function helical_twist_per_segment(r, pitch, sides) =
    let(lt = 2 * r * sin(360 / sides),
        slope = atan(2 * pitch / sides / lt))
        (360 / sides) * sin(slope);

function transpose3(m) = [[m[0].x, m[1].x, m[2].x],
                           [m[0].y, m[1].y, m[2].y],
                           [m[0].z, m[1].z, m[2].z]];

function find_curve(tangents, i = 1) =
    i >= len(tangents) - 1 || norm(cross(tangents[0], tangents[i] - tangents[0])) > 0.00001 ? i
        : find_curve(tangents, i + 1);

function fs_frame(tangents) =
    let(tangent = tangents[0], i = find_curve(tangents),
        normal = tangents[i] - tangents[0],
        binormal = cross(tangent, normal),
        z = unit(tangent),
        x = unit(binormal),
        y = unit(cross(z, x)))
        [[x.x, y.x, z.x], [x.y, y.y, z.y], [x.z, y.z, z.z]];

function rotate_from_to(a, b) =
    let(axis = unit(cross(a, b)))
        axis * axis >= 0.99 ? transpose3([b, axis, cross(axis, b)]) * [a, axis, cross(axis, a)]
                            : a * b > 0 ? [[1,0,0],[0,1,0],[0,0,1]]
                                        : [[-1,0,0],[0,1,0],[0,0,-1]];

function orientate(p, r) =
    let(x = r[0], y = r[1], z = r[2])
        [[x.x, y.x, z.x], [x.y, y.y, z.y], [x.z, y.z, z.z], [p.x, p.y, p.z]];

function rot3_z(a) = let(c = cos(a), s = sin(a)) [[c,-s,0],[s,c,0],[0,0,1]];

function tangent(path, before, i, after) = unit(unit(path[i] - path[before]) + unit(path[after] - path[i]));

function sweep_transforms(path, twist = 0) =
    let(len = len(path), last = len - 1,
        tangents = [tangent(path, 0, 0, 1),
                    for(i = [1 : last - 1]) tangent(path, i - 1, i, i + 1),
                    tangent(path, last - 1, last, last)],
        lengths = [for(i = 0, t = 0; i < len; t = t + norm(path[min(i + 1, last)] - path[i]), i = i + 1) t],
        length = lengths[last],
        rotations = [for(i = 0, rot = fs_frame(tangents);
                         i < len; i = i + 1,
                         rot = i < len ? rotate_from_to(tangents[i - 1], tangents[i]) * rot : undef) rot])
    [for(i = [0 : last]) let(za = twist * lengths[i] / length) orientate(path[i], rotations[i] * rot3_z(za))];

function skin_points(profile, path, twist = 0) =
    let(profile4 = [for(p = profile) [p.x, p.y, p.z, 1]],
        transforms = sweep_transforms(path, twist))
    [for(t = transforms) each profile4 * t];

function cap(facets, segment = 0, end) =
    let(reverse = is_undef(end) ? segment : end)
        [for(i = [0 : facets - 1]) facets * segment + (reverse ? i : facets - 1 - i)];

function quad(p, a, b, c, d) = norm(p[a] - p[c]) > norm(p[b] - p[d]) ? [[b,c,d],[b,d,a]] : [[a,b,c],[a,c,d]];

function skin_faces(points, npoints, facets, offset = 0) =
    [for(i = [0 : facets - 1], s = [0 : npoints - 2])
       let(j = s + offset, k = j + 1)
       each quad(points, j*facets+i, j*facets+(i+1)%facets, k*facets+(i+1)%facets, k*facets+i)];

function thread_profile(h, crest, angle, overlap = 0.1) =
    let(base = crest + 2 * (h + overlap) * tan(angle / 2))
        [[-base / 2, -overlap, 0], [-crest / 2, h, 0], if(crest) [crest / 2, h, 0], [base / 2, -overlap, 0]];

module male_metric_thread(d, pitch, length, body_color) {
    H = pitch * sqrt(3) / 2;
    h = 5 * H / 8;
    minor_d = d - 2 * h;
    profile = thread_profile(h, pitch / 8, 60);

    r = minor_d / 2;
    sides = r2sides4n(r);
    step_angle = 360 / sides;
    scale = cos(atan(pitch / (PI * minor_d)));
    sprofile = [for(p = profile) [p.x * scale, p.y, p.z]];
    ph = max([for(p = sprofile) p.y]);
    overlap = -profile[0].y;
    turns = length / pitch;
    segs = ceil(turns * sides);
    leadin = min(ceil(sides), floor(turns * sides / 2));
    final = floor(turns * sides) - leadin;

    path = [for(i = [0 : segs],
                R = i < leadin ? r - (ph - ph * i / leadin)
                  : i > final  ? r - ph * (i - final) / leadin : r,
                a = i * step_angle)
                    [R * cos(a), R * sin(a), a * pitch / 360]];

    twist = helical_twist_per_segment(r, pitch, sides);
    rprofile = transform_points(sprofile, rotate_m((helical_twist_per_segment(r - ph, pitch, sides) - twist) * sides / PI));
    points = skin_points(rprofile, path, twist * segs);
    facets = len(profile);

    xs = [for(p = sprofile) p.x];
    maxx = max(xs);
    top_overlap = maxx / pitch;
    bot_overlap = -min(xs) / pitch;
    start =      ceil(sides * bot_overlap);
    end = segs - ceil(sides * top_overlap);

    start_skin_faces  = skin_faces(points, start + 1,       facets);
    middle_skin_faces = skin_faces(points, end - start + 1, facets, start);
    end_skin_faces    = skin_faces(points, segs - end + 1,  facets, end);

    start_faces  = concat([cap(facets)              ], start_skin_faces,  [cap(facets, start)]);
    middle_faces = concat([cap(facets, start, false)], middle_skin_faces, [cap(facets, end)]);
    end_faces    = concat([cap(facets, end,   false)], end_skin_faces,    [cap(facets, segs)]);

    ends_faces = concat(start_faces, end_faces);

    color(body_color * 0.8) {
        render() intersection() {
            polyhedron(points, ends_faces);
            rotate_extrude()
                hull() {
                    translate([0, eps])
                        square([r, length - 2 * eps]);
                    translate([0, eps])
                        square([r + ph + overlap, length - 2 * eps]);
                }
        }
        polyhedron(points, middle_faces);
    }

    color(body_color)
        rotate(90)
            cylinder(d = minor_d, h = length);
}

// --- Render ---


module rounded_square(size, r, center = true)
{
    assert(r < min(size.x, size.y) / 2);
    color(body_color) offset(r) offset(-r) square(size, center = center);
}


module body() {
  intersection() {
    color(body_color) cube([12,10.5,17], center=true);
    male_metric_thread(12, 1.0, 12, body_color);
  }
  translate([0,0,8])
    color(body_color) cylinder(h = 2, r1 = 15/2, r2 = 12/2);

}

// datasheet width + tolerance
w = 8.94 + 0.36;
h = 3.26 + 0.04;

module usb()
{
  rotate([0,0,45])
    translate([0, 0,6])
      color(body_color) linear_extrude(height = 13, center = true, convexity = 10, twist = 0)
         rounded_square([w, h], h / 2 - 0.5, center = true);
}

rotate([0,180,0]) translate([0,0,-10])
difference() {
  body();
  usb();
}

