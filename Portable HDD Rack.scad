$fn = 20;
// Set to 0.01 for higher definition curves (renders slower)
$fs = 0.5;
//------------
// Start HDDock Specific Section
function rand_int(mins=0,maxs=100)=round(rands(mins,maxs,1)[0]);

function input_to_struct(details, index) =
let (
struct=[],
device_name=str("Device ",index+1),
usb_type=downcase(details[3]),
test1=assert(is_string(usb_type)),
usb_details=struct_val(USB_STRUCT,usb_type),
test2=assert(!is_undef(usb_type),str("Your USB type must be one of",struct_keys(USB_STRUCT))),
conn_height=struct_val(usb_details,"conn_height"),
conn_width=struct_val(usb_details,"conn_width"),
drive_height=details[1],
drive_height_padded=max(drive_height,is_def(conn_height) ? conn_height: 0)+Y_PAD*2,
drive_width_padded=max(details[0],(is_def(conn_width) ? conn_width: 0))+X_PAD*2,
vUSB=max(min(details[5],drive_height_padded),-Y_WALL),
hUSB=max(min(details[4],drive_width_padded-(is_def(conn_width) ? conn_width: 0)),-X_WALL),
d_depth=details [2],
new_struct=struct_set(struct,
["width_padded",drive_width_padded,
"width_unpadded",details[0],
"depth",d_depth,
"type",usb_type,
"conn_height",conn_height,
"conn_width",drive_width_padded,
"height_padded",drive_height_padded,
"height_unpadded",drive_height,
"vUSB",vUSB,
"hUSB",hUSB,
"count",details[6],
"index",index,
"device_name",device_name,
]
),
)
[device_name,new_struct];
function x_at_index(index,val) =   struct_val(DATA_STRUCT[index][1],val) ;

function parse_input(hole_list_str)=
let (
struct=[],
strip_outer=str_strip(hole_list_str," ,"),
//    q=echo(strip_outer),
split_by_comma=str_split(strip_outer, ",", true),
//    f=echo(split_by_comma),
split_out=[for (x=split_by_comma) str_split(str_strip(x, " m"), "x", false)],
//    z=echo(split_out),
to_float=[for (x=split_out) [for (y=x) if(is_num(str_float(y))) str_float(y) else y]],
to_struct=[for (index=[0:1:len(to_float)-1]) input_to_struct(to_float[index],index=index)]
)
to_struct ;

// Show an echo or an assert depending on the parameters
function custom_log(textin, tester, stop_if_fails, skip, show_if_pass=true) =
skip ? (
stop_if_fails ?
assert(tester): show_if_pass || show_if_pass ? echo(textin): undef
)
: undef;

// Global variables

/* [Input] */
// Coordinates are measured from bottom left corner
// mm units
// <W>x<H>x<D>x<C|Micro|3_Micro|Mini|None>x<X USB Coords>x<Y USB Coords>x<COUNT>
text_list="
80.3x15.7x110.6x3_Microx75x1x1,
78.5x20.7x114.6x3_Microx75x1x1,
75x9.2x107x3_Microx25x3x1
";

// EXAMPLES
// WD My Passport Ultra
// 80.3x15.7x110.6x3_Microx75x1x1
// Seagate Backup Plus
// 78.5x20.7x114.6x3_Microx75x1x1
// Toshiba
// 75x9.2x107x3_Microx25x3x1
// Empty
// 114.5x15.5x114.6xNonex25x3x1

// RANDOM EXAMPLE MAKER
//text_list=str("80x14x100xMicrox",rand_int(-10,80),"x",rand_int(-5,14),"x",rand_int(1,5),", ", rand_int(63.5,90),"x",rand_int(4,10),"x",rand_int(14,90),"x","3_Microx",rand_int(1,90),"x",rand_int(1,10),"x",rand_int(1,5));


//mm
side_wall_thickness=2.5; //[0.3:0.1:6]
//mm
top_bottom_wall_thickness=2.5; //[0.3:0.1:6]
//mm
rear_wall_thickness=2.5; //[0.3:0.1:6]
//mm on each side (multiplies by 2)
vertical_padding=1.5; //[0.1:0.1:16]
//mm on each side (multiplies by 2)
side_padding=0.1; //[0:0.1:6]
//Depth of a rear shield in mm
rear_shield=0; //[0:1:60]
//Rounding of outside corners in mm
rounding_radius=2; //[0:0.2:4]
//If true, left align drives in the cage.
left_align=false; 
//Diameter of round rubber feet you add separately
rubber_feet_diameter=5; //[0:0.1:15]
rubber_feet_depth=0.4; //[0:0.1:6]
// If your port alignment gets too close to an outer wall,  should it clip?
port_hole_can_intersect_side_walls = true;


/* [USB Tweaking] */
//mm
USB_C_Height = 6.2;
//mm
USB_C_Width = 10.1;
//mm
USB_3_Micro_Height = 7.5;
//mm
USB_3_Micro_Width = 14.9;
//mm
USB_Micro_Height = 5.9;
//mm
USB_Micro_Width = 10.6;
//mm
USB_Mini_Height = 6;
//mm
USB_Mini_Width = 10;



/* [Debugging] */
ENABLE_DEBUGGING=false;


// Height limit in mm
MAX_BOX_HEIGHT = 88;


/* [Hidden] */
color_start=0.5;
spacer=0.02;
RUBBER_FEET_DEPTH_N=rubber_feet_depth;
RUBBER_FEET_DIAMETER_N=rubber_feet_diameter;
REAR_WALL=min(max(rear_wall_thickness,0.3),250);
Y_WALL=min(max(top_bottom_wall_thickness,0.3),250);
X_WALL=min(max(side_wall_thickness,0.3),250);
SHIELD_DEPTH=min(max(rear_shield,0),250);
Y_PAD = vertical_padding;
X_PAD = side_padding;
USB_CONNECTOR_DEPTH=0.5;


USB_STRUCT = [
["c",[
["conn_height",USB_C_Height],
["conn_width",USB_C_Width]
]
],
["3_micro",[
["conn_height",USB_3_Micro_Height],
["conn_width",USB_3_Micro_Width]]
],
["micro",[
["conn_height",USB_Micro_Height],
["conn_width",USB_Micro_Width]
],
],
["mini",[
["conn_height",USB_Micro_Height],
["conn_width",USB_Micro_Width]
],
]
];

DATA_STRUCT=parse_input(text_list);
MAX_INDEX=len(DATA_STRUCT)-1;
COUNT_AT_MAX_INDEX=x_at_index(MAX_INDEX,"count");

if (ENABLE_DEBUGGING) {
  echo(str("Your total height is ",CAGE_HEIGHT,"mm"));
  echo(str("Your total width is ",CAGE_WIDTH,"mm"));
  echo(str("Top bottom wall thickness ",Y_WALL));
  echo(str("Vertical padding ",Y_PAD));
  echo(str("MAX_INDEX ",Y_PAD));
  echo(str("COUNT_AT_MAX_INDEX ",COUNT_AT_MAX_INDEX));
  for (kv=DATA_STRUCT){
    details = kv[1];
    usb_type=struct_val(details,"type");
    usb_details=struct_val(USB_STRUCT,usb_type);
    echo(str("For ",kv[0],"\nThe data made is:\n",details));
  }
}


function index_height(index,count)=
let(
test1=assert(count<=x_at_index(index,"count")),
d_height=x_at_index(index,"height_padded"),
is_first=index==0 && count==1,
max_index=MAX_INDEX,
is_max_index = MAX_INDEX==index,
is_last=is_max_index && count == COUNT_AT_MAX_INDEX,
last_add = is_last ? Y_WALL : 0,
first_add = is_first ? FEET_VDIFF : 0
)
d_height
+ last_add
+ Y_WALL
+first_add
;

function height_to_index2(to_index,to_count,include=false) = 
let (
index_goal=min(to_index,MAX_INDEX),
to_count_N=to_count,
past_first=to_index>=0 && to_count_N>=1,
f_sub=past_first ? index_height(0,1): 0,
r=[for (index=[0:1:index_goal]) [for (count=[
1:1: 
(
to_index == index ? to_count_N :
x_at_index(index,"count"))
])
index_height(index,count) 

]],
rb=flatten(r),
re=include ? rb: list_remove(rb,len(rb)-1),
)
re
;


function height_to_index(to_index,to_count,include=false) = sum(
flatten(height_to_index2(to_index,to_count,include=include)
));

FEET_VDIFF = max(RUBBER_FEET_DEPTH_N-Y_WALL,0);
TOTAL_COUNT = sum([for (x=[0:1:MAX_INDEX]) struct_val(DATA_STRUCT[x][1],"count")]);
CAGE_HEIGHT = height_to_index(to_index=MAX_INDEX,to_count= COUNT_AT_MAX_INDEX,include=true);
CAGE_WIDTH = max([for (x=[0:1:MAX_INDEX])
(struct_val(DATA_STRUCT[x][1],"width_padded")+X_WALL*2)]);
CAGE_DEPTH = max([for (x=[0:1:MAX_INDEX])
(struct_val(DATA_STRUCT[x][1],"depth")+REAR_WALL)])+SHIELD_DEPTH;



module all_feet() {
  // Add feet
  translate([0,0,RUBBER_FEET_DEPTH_N-spacer])
  union() {
    x=RUBBER_FEET_DIAMETER_N+X_WALL;
    y=-RUBBER_FEET_DEPTH_N-spacer;
    zu=RUBBER_FEET_DIAMETER_N+REAR_WALL+SHIELD_DEPTH;
    zd=-RUBBER_FEET_DIAMETER_N-REAR_WALL+CAGE_DEPTH;
    translate([x,zd,y])
    feet(CAGE_HEIGHT, CAGE_WIDTH, CAGE_DEPTH+spacer);
    
    translate([CAGE_WIDTH-x,zd,y])
    feet(CAGE_HEIGHT, CAGE_WIDTH, CAGE_DEPTH+spacer);
    
    translate([x,zu,y])
    feet(CAGE_HEIGHT, CAGE_WIDTH, CAGE_DEPTH+spacer);
    
    translate([CAGE_WIDTH+-x,zu,y])
    feet(CAGE_HEIGHT, CAGE_WIDTH, CAGE_DEPTH+spacer);
  }
  
}

module feet(drive_height, drive_width, d_depth) {
  translate([ 0,0,0])
  cylinder(r=RUBBER_FEET_DIAMETER_N, h=RUBBER_FEET_DEPTH_N, center=false);  
}

module chamber(details) {
  drive_height = struct_val(details, "height_padded");
  drive_width = struct_val(details, "width_padded");
  drive_depth = struct_val(details, "depth");
  index = struct_val(details, "index");
  count = struct_val(details, "count");
  lr_adjust = left_align && (drive_width*2+X_WALL*2 != CAGE_WIDTH)  ? CAGE_WIDTH-drive_width-X_WALL*2: 0;
  for (curr_count=[1:1:count]) {
    height_so_far = height_to_index(to_index=index, to_count=curr_count);
    first=curr_count==1 && index==0;
    translate([X_WALL, REAR_WALL, Y_WALL])
    translate([lr_adjust, CAGE_DEPTH-drive_depth, height_so_far + (!first?0:FEET_VDIFF)])//MOVE CAGES UP/DOWN
    color([1,0,0])
    cube(size=[drive_width, drive_depth, drive_height], center=false);
  }
}


module ports(details) {
  drive_width = struct_val(details, "width_padded");
  d_depth = struct_val(details, "depth");
  USB_type = struct_val(details, "type");
  vUSB = struct_val(details, "vUSB");
  hUSB = struct_val(details, "hUSB");
  count = struct_val(details, "count");
  conn_height = struct_val(details, "conn_height");
  conn_width = struct_val(details, "conn_width");
  
  for (curr_count=[1:1:count]) {
    if (is_def(conn_height) && is_def(conn_width) && USB_type != "none") {
      //            difference() 
      {
        hull() {
          conn_depth = CAGE_DEPTH-d_depth+REAR_WALL+spacer*2;
          translate([X_WALL+hUSB + X_PAD, conn_depth-spacer,vUSB+Y_WALL])
          port( conn_height,conn_width,conn_depth,vUSB,hUSB);      
        }
        if (port_hole_can_intersect_side_walls) {
          c_size=max((conn_height<=conn_width? conn_width/2 :conn_height/2),CAGE_WIDTH);
          //              color([0.5,0.7,0])
          //              translate([(left_align ? -1: 1)*((left_align ? 0: CAGE_WIDTH)+c_size+(port_hole_can_intersect_side_walls?+spacer*3:X_WALL*2)+spacer), 
          //              -spacer*3,
          //              -vUSB-(conn_height>conn_width? conn_width :conn_height)
          //              ])
          //              mirror([(left_align ? 0: 1),0,0])
          //              cube(size=[(port_hole_can_intersect_side_walls?0:CAGE_WIDTH-drive_width+X_WALL)+c_size, d_depth+SHIELD_DEPTH+spacer*3, drive_height+(conn_height>conn_width? conn_width/2 :conn_height/2)*2], center=false);
        }
      }
    }
  }
}



module port(conn_height,conn_width,conn_depth,vUSB,hUSB) {
  hole_radius = conn_height>conn_width? conn_width/2 :conn_height/2;
  rotate([90,0,0])
  hull()
  {
    translate([ conn_height<=conn_width ? conn_height/2-hole_radius:0,conn_height>conn_width ? conn_height/2-hole_radius:0,0])
    cylinder(r=hole_radius, h=conn_depth, center=false);
    
    
    //    translate([(max(conn_height,conn_width))/2,0,0, ])  cylinder(r=hole_radius, h=conn_depth, center=false);
  }
}


module full_box(data_struct) {
  
  //    difference() 
  {
    difference() 
    {
      color("pink")
      // Hard Drive Slots
      if (rounding_radius == 0) {
        cube(size=[CAGE_WIDTH, CAGE_DEPTH, CAGE_HEIGHT], center=false);
      }
      else {
        roundedcube(size = [CAGE_WIDTH, CAGE_DEPTH, CAGE_HEIGHT  ], center = false, radius = rounding_radius, apply_to = "all");
      }
      
      union() {
        for (details=[for (x=data_struct) x[1]]) {
          chamber(details=details);
        }
        if (SHIELD_DEPTH > 0) {
          translate([X_WALL, -0.1, -spacer])
          color([1,0.5,0])
          cube(size=[CAGE_WIDTH-X_WALL*2,SHIELD_DEPTH,CAGE_HEIGHT-Y_WALL+spacer], center=false);
        }
        
        all_feet() ;
      }
      
    }
    
    for (details=[for (x=data_struct) x[1]]) {
      ports(details=details);
    }
  }
}

full_box(DATA_STRUCT);


//-------------------------
// BOSL2 Functions
// Copyright (c) 2017-2019, Revar Desmera
// All rights reserved.
// https://github.com/revarbat/BOSL2/blob/0e999084406aad0c091460e92711c28ef5253ded/LICENSE
//
function str_split(str,sep,keep_nulls=true) =
!keep_nulls ? _remove_empty_strs(str_split(str,sep,keep_nulls=true)) :
is_list(sep) ? _str_split_recurse(str,sep,i=0,result=[]) :
let( cutpts = concat([-1],sort(flatten(search(sep, str,0))),[len(str)]))
[for(i=[0:len(cutpts)-2]) substr(str,cutpts[i]+1,cutpts[i+1]-cutpts[i]-1)];

function _str_split_recurse(str,sep,i,result) =
i == len(sep) ? concat(result,[str]) :
let(
pos = search(sep[i], str),
end = pos==[] ? len(str) : pos[0]
)
_str_split_recurse(
substr(str,end+1),
sep, i+1,
concat(result, [substr(str,0,end)])
);

function _remove_empty_strs(list) =
list_remove(list, search([""], list,0)[0]);

function substr(str, pos=0, len=undef) =
is_list(pos) ? _substr(str, pos[0], pos[1]-pos[0]+1) :
len == undef ? _substr(str, pos, len(str)-pos) :
_substr(str,pos,len);

function _substr(str,pos,len,substr="") =
len <= 0 || pos>=len(str) ? substr :
_substr(str, pos+1, len-1, str(substr, str[pos]));
function flatten(l) =
!is_list(l)? l :
[for (a=l) if (is_list(a)) (each a) else a];

function struct_val(struct, keyword, default=undef) =
assert(is_def(keyword),"keyword is missing")
let(ind = search([keyword],struct)[0])
ind == [] ? default : struct[ind][1];
function struct_set(struct, keyword, value=undef, grow=true) =
!is_list(keyword)? (
let( ind=search([keyword],struct,1,0)[0] )
ind==[]? (
assert(grow,str("Unknown keyword \"",keyword))
concat(struct, [[keyword,value]])
) : list_set(struct, [ind], [[keyword,value]])
) : _parse_pairs(struct,keyword,grow);


function _parse_pairs(spec, input, grow=true, index=0, result=undef) =
assert(len(input)%2==0,"Odd number of entries in [keyword,value] pair list")
let( result = result==undef ? spec : result)
index == len(input) ? result :

_parse_pairs(spec,input,grow,index+2,struct_set(result, input[index], input[index+1],grow));

function sort(list, idx=undef) =
assert(is_list(list)||is_string(list), "Invalid input." )
is_string(list)? str_join(sort([for (x = list) x],idx)) :
!is_list(list) || len(list)<=1 ? list :
is_homogeneous(list,1)
?   let(size = list_shape(list[0]))
size==0 ?         _sort_scalars(list)
: len(size)!=1 ?  _sort_general(list,idx)
: is_undef(idx) ? _sort_vectors(list)
: assert( _valid_idx(idx) , "Invalid indices.")
_sort_vectors(list,[for(i=idx) i])
: _sort_general(list,idx);
function is_homogeneous(l, depth=10) =
!is_list(l) || l==[] ? false :
let( l0=l[0] )
[] == [for(i=[1:1:len(l)-1]) if( ! _same_type(l[i],l0, depth+1) )  0 ];

function is_homogenous(l, depth=10) = is_homogeneous(l, depth);


function _same_type(a,b, depth) =
(depth==0) ||
(is_undef(a) && is_undef(b)) ||
(is_bool(a) && is_bool(b)) ||
(is_num(a) && is_num(b)) ||
(is_string(a) && is_string(b)) ||
(is_list(a) && is_list(b) && len(a)==len(b)
&& []==[for(i=idx(a)) if( ! _same_type(a[i],b[i],depth-1) ) 0] );
function list_shape(v, depth=undef) =
assert( is_undef(depth) || ( is_finite(depth) && depth>=0 ), "Invalid depth.")
! is_list(v) ? 0 :
(depth == undef)
?   concat([len(v)], _list_shape_recurse(v))
:   (depth == 0)
?  len(v)
:  let( dimlist = _list_shape_recurse(v))
(depth > len(dimlist))? 0 : dimlist[depth-1] ;
function _sort_scalars(arr) =
len(arr)<=1 ? arr :
let(
pivot   = arr[floor(len(arr)/2)],
lesser  = [ for (y = arr) if (y  < pivot) y ],
equal   = [ for (y = arr) if (y == pivot) y ],
greater = [ for (y = arr) if (y  > pivot) y ]
)
concat( _sort_scalars(lesser), equal, _sort_scalars(greater) );

function list_remove(list, ind) =
assert(is_list(list), "Invalid list in list_remove")
is_finite(ind) ?
(
(ind<0 || ind>=len(list)) ? list
:
[
for (i=[0:1:ind-1]) list[i],
for (i=[ind+1:1:len(list)-1]) list[i]
]
)
:   ind==[] ? list
:   assert( is_vector(ind), "Invalid index list in list_remove")
let(sres = search(count(list),ind,1))
[
for(i=idx(list))
if (sres[i] == [])
list[i]
];

function downcase(str) =
str_join([for(char=str) let(code=ord(char)) code>=65 && code<=90 ? chr(code+32) : char]);
function is_finite(x) = is_num(x) && !is_nan(0*x);
function str_strip(s,c) = str_strip_trailing(str_strip_leading(s,c),c);
function str_strip_trailing(s,c) = substr(s,len=len(s)-_str_count_trailing(s,c));
function str_strip_leading(s,c) = substr(s,pos=_str_count_leading(s,c));
function substr(str, pos=0, len=undef) =
is_list(pos) ? _substr(str, pos[0], pos[1]-pos[0]+1) :
len == undef ? _substr(str, pos, len(str)-pos) :
_substr(str,pos,len);
function is_nan(x) = (x!=x);
function _substr(str,pos,len,substr="") =
len <= 0 || pos>=len(str) ? substr :
_substr(str, pos+1, len-1, str(substr, str[pos]));

function _str_count_leading(s,c,_i=0) =
(_i>=len(s)||!in_list(s[_i],[each c]))? _i :
_str_count_leading(s,c,_i=_i+1);

function in_list(val,list,idx) =
assert(is_list(list),"Input is not a list")
assert(is_undef(idx) || is_finite(idx), "Invalid idx value.")
let( firsthit = search([val], list, num_returns_per_match=1, index_col_num=idx)[0] )
firsthit==[] ? false
: is_undef(idx) && val==list[firsthit] ? true
: is_def(idx) && val==list[firsthit][idx] ? true
// first hit was found but didn't match, so try again with all hits
: let ( allhits = search([val], list, 0, idx)[0])
is_undef(idx) ? [for(hit=allhits) if (list[hit]==val) 1] != []
: [for(hit=allhits) if (list[hit][idx]==val) 1] != [];

function is_def(x) = !is_undef(x);
function struct_keys(struct) =
[for(entry=struct) entry[0]];
function _str_count_trailing(s,c,_i=0) =
(_i>=len(s)||!in_list(s[len(s)-1-_i],[each c]))? _i :
_str_count_trailing(s,c,_i=_i+1);


function str_float(str) =
str==undef ? undef :
len(str) == 0 ? 0 :
in_list(str[1], ["+","-"]) ? (0/0) : // Don't allow --3, or +-3
str[0]=="-" ? -str_float(substr(str,1)) :
str[0]=="+" ?  str_float(substr(str,1)) :
let(esplit = str_split(str,"eE") )
len(esplit)==2 ? str_float(esplit[0]) * pow(10,str_int(esplit[1])) :
let( dsplit = str_split(str,["."]))
str_int(dsplit[0])+str_int(dsplit[1])/pow(10,len(dsplit[1]));

function str_int(str,base=10) =
str==undef ? undef :
len(str)==0 ? 0 :
let(str=downcase(str))
str[0] == "-" ? -_str_int_recurse(substr(str,1),base,len(str)-2) :
str[0] == "+" ?  _str_int_recurse(substr(str,1),base,len(str)-2) :
_str_int_recurse(str,base,len(str)-1);

function _str_int_recurse(str,base,i) =
let(
digit = search(str[i],"0123456789abcdef"),
last_digit = digit == [] || digit[0] >= base ? (0/0) : digit[0]
) i==0 ? last_digit :
_str_int_recurse(str,base,i-1)*base + last_digit;
function downcase(str) =
str_join([for(char=str) let(code=ord(char)) code>=65 && code<=90 ? chr(code+32) : char]);

function str_join(list,sep="",_i=0, _result="") =
_i >= len(list)-1 ? (_i==len(list) ? _result : str(_result,list[_i])) :
str_join(list,sep,_i+1,str(_result,list[_i],sep));
function sum(v, dflt=0) =
v==[]? dflt :
assert(is_consistent(v), "Input to sum is non-numeric or inconsistent")
is_finite(v[0]) || is_vector(v[0]) ? [for(i=v) 1]*v :
_sum(v,v[0]*0);

function _sum(v,_total,_i=0) = _i>=len(v) ? _total : _sum(v,_total+v[_i], _i+1);
function is_consistent(list, pattern) =
is_list(list)
&& (len(list)==0
|| (let(pattern = is_undef(pattern) ? _list_pattern(list[0]): _list_pattern(pattern) )
[]==[for(entry=0*list) if (entry != pattern) entry]));

//Creates a list with the same structure of `list` with each of its elements replaced by 0.
function _list_pattern(list) =
is_list(list)
? [for(entry=list) is_list(entry) ? _list_pattern(entry) : 0]
: 0;


//END BOSL2

// RoundedCorners from Daniel Shaw, copied from groovenectar's version on 11-21-2021
// https://gist.github.com/groovenectar/92174cb1c98c1089347e
// No license is attached. If you are an owner, please contact me if incorrect.
// More information: https://danielupshaw.com/openscad-rounded-corners/


module roundedcube(size = [1, 1, 1], center = false, radius = 0.5, apply_to = "all") {
  // If single value, convert to [x, y, z] vector
  size = (size[0] == undef) ? [size, size, size] : size;
  
  translate_min = radius;
  translate_xmax = size[0] - radius;
  translate_ymax = size[1] - radius;
  translate_zmax = size[2] - radius;
  
  diameter = radius * 2;
  
  obj_translate = (center == false) ?
  [0, 0, 0] : [
  -(size[0] / 2),
  -(size[1] / 2),
  -(size[2] / 2)
  ];
  
  translate(v = obj_translate) {
    hull() {
      for (translate_x = [translate_min, translate_xmax]) {
        x_at = (translate_x == translate_min) ? "min" : "max";
        for (translate_y = [translate_min, translate_ymax]) {
          y_at = (translate_y == translate_min) ? "min" : "max";
          for (translate_z = [translate_min, translate_zmax]) {
            z_at = (translate_z == translate_min) ? "min" : "max";
            
            translate(v = [translate_x, translate_y, translate_z])
            if (
            (apply_to == "all") ||
            (apply_to == "xmin" && x_at == "min") || (apply_to == "xmax" && x_at == "max") ||
            (apply_to == "ymin" && y_at == "min") || (apply_to == "ymax" && y_at == "max") ||
            (apply_to == "zmin" && z_at == "min") || (apply_to == "zmax" && z_at == "max")
            ) {
              sphere(r = radius);
            } else {
              rotate = 
              (apply_to == "xmin" || apply_to == "xmax" || apply_to == "x") ? [0, 90, 0] : (
              (apply_to == "ymin" || apply_to == "ymax" || apply_to == "y") ? [90, 90, 0] :
              [0, 0, 0]
              );
              rotate(a = rotate)
              cylinder(h = diameter, r = radius, center = true);
            }
          }
        }
      }
    }
  }
}
