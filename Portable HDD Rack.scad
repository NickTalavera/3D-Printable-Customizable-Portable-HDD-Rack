$fn = 30;


//------------
// Copyright (c) 2021, Nick Talavera
// All rights reserved.
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
d_height=max(details[1],is_def(conn_height) ? conn_height: 0)+vertical_padding*2,

d_width=max(details[0],(is_def(conn_width) ? conn_width: 0))+side_padding*2,
vUSB=max(min(details[5],d_height),-top_bottom_wall_thickness),
hUSB=max(min(details[4],d_width-(is_def(conn_width) ? conn_width: 0)),-side_wall_thickness),
d_depth=details [2],
new_struct=struct_set(struct,
["width",d_width,
"depth",d_depth,
"type",usb_type,
"conn_height",conn_height,
"conn_width",conn_width,
"height",d_height,
"vUSB",vUSB,
"hUSB",hUSB,
"count",details[6],
"index",index,
"device_name",device_name,
]
),
)
[device_name,new_struct];


function parseInput(hole_list_str)=
let (
struct=[],
split_by_comma=str_split(hole_list_str, ",", false),
split_out=[for (x=split_by_comma) str_split(str_strip(x, " m"), "x", false)],
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
//<W>x<H>x<D>x<C|Micro|3_Micro|Mini|None>x<X USB Coords>x<Y USB Coords>x<COUNT>
text_list="80x15.5x110.6x3_Microx75x1x1 , 114.5x20.5x114.6x3_Microx75x1x1,
75x7.3x107x3_Microx25x3x1,
114.5x15.5x114.6xNonex25x3x1
";

// WD Ultra
// 80x15.5x110.6x3_Microx75x1x1
// Seagate Backup Plus
// 114.5x20.5x114.6x3_Microx75x1x1
// Toshiba
// 75x7.3x107x3_Microx25x3x1

//text_list=str("80x14x100xMicrox",rand_int(-10,80),"x",rand_int(-5,14),"x",rand_int(1,5),", ", rand_int(63.5,90),"x",rand_int(4,10),"x",rand_int(14,90),"x","3_Microx",rand_int(1,90),"x",rand_int(1,10),"x",rand_int(1,5));



side_wall_thickness=2.5;
top_bottom_wall_thickness=2.5;
rear_wall_thickness=2.5;
vertical_padding=0.1;
side_padding=0.1;
outer_corner_rounding = 3;
left_align=false;
rear_shield=5;

/* [USB Tweaking] */
USB_C_Height = 6.2;
USB_C_Width = 10.1;
USB_3_Micro_Height = 7.5;
USB_3_Micro_Width = 14.9;
USB_Micro_Height = 5.9;
USB_Micro_Width = 10.6;
USB_Mini_Height = 6;
USB_Mini_Width = 10;

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

/* [Debugging] */
ENABLE_DEBUGGING=false;


// Height limit in mm
MAX_BOX_HEIGHT = 88;


/* [Hidden] */
H_PAD = top_bottom_wall_thickness*2;
W_PAD = side_wall_thickness*2;
color_start=0.5;

DATA_STRUCT=parseInput(text_list);


if (ENABLE_DEBUGGING) {
  echo(str("Your total height is ",CAGE_HEIGHT,"mm"));
  echo(str("Your total width is ",CAGE_WIDTH,"mm"));
  echo(str("Your data is ",DATA_STRUCT));
  for (kv=DATA_STRUCT){
    details = kv[1];
    usb_type=struct_val(details,"type");
    usb_details=struct_val(USB_STRUCT,usb_type);
    echo(str("For ",kv[0],"\nThe data made is:\n",details));
  }
}


TOTAL_COUNT = sum([for (x=[0:1:len(DATA_STRUCT)-1]) struct_val(DATA_STRUCT[x][1],"count")]);
CAGE_HEIGHT = sum([for (x=[0:1:len(DATA_STRUCT)-1])
struct_val(DATA_STRUCT[x][1],"count") * (struct_val(DATA_STRUCT[x][1],"height")+H_PAD)]);
CAGE_WIDTH = max([for (x=[0:1:len(DATA_STRUCT)-1])
(struct_val(DATA_STRUCT[x][1],"width")+W_PAD)]);
CAGE_DEPTH = max([for (x=[0:1:len(DATA_STRUCT)-1])
(struct_val(DATA_STRUCT[x][1],"depth")+rear_wall_thickness)]);

module container(kv){
  device_name = kv[0];
  details = kv[1];
  d_height = struct_val(details, "height");
  d_width = struct_val(details, "width");
  d_depth = struct_val(details, "depth");
  USB_type = struct_val(details, "type");
  vUSB = struct_val(details, "vUSB");
  hUSB = struct_val(details, "hUSB");
  index = struct_val(details, "index");
  count = struct_val(details, "count");
  height_so_far = sum([for (x=[0:1:index-1])
  struct_val(DATA_STRUCT[x][1],"count") * (struct_val(DATA_STRUCT[x][1],"height")+H_PAD)]);
  count_so_far = sum([for (x=[0:1:index-1]) struct_val(DATA_STRUCT[x][1],"count")]);

  conn_height = struct_val(details, "conn_height");
  conn_width = struct_val(details, "conn_width");
  full_height = d_height+H_PAD;
  full_depth = d_depth+rear_wall_thickness;
  lr_adjust = left_align && (d_width+W_PAD != CAGE_WIDTH)  ? CAGE_WIDTH-d_width-W_PAD: 0;
  //make cubby
  for (curr_count=[0:1:count-1]) {

    //Color as a ratio of the counts so far out of the total count


    difference()
    {
      color([0,color_start+((count_so_far+curr_count)/TOTAL_COUNT)*(1-color_start),color_start+((count_so_far+curr_count)/TOTAL_COUNT)*(1-color_start)])
      translate([0, rear_shield, height_so_far+full_height*curr_count])
      difference()
      {
        // Hard Drive Slots
        // Outer Shell
        translate([0, -rear_shield, 0])
        cube(size=[CAGE_WIDTH, CAGE_DEPTH+rear_shield, full_height], center=false);
        //Inner hollow
        union () {
          translate([lr_adjust, CAGE_DEPTH-full_depth+rear_wall_thickness, 0])
          cubby(conn_height,conn_width, d_height, d_width, d_depth,USB_type,vUSB,hUSB);


        }
      }


      // Make rear shield
      echo("CAGE_HEIGHT",CAGE_HEIGHT);

      translate([side_wall_thickness, -0.1, -top_bottom_wall_thickness])
      cube(size=[
      CAGE_WIDTH-side_wall_thickness*2,rear_shield,CAGE_HEIGHT
      ], center=false);
    }
  }

}


module cubby(conn_height,conn_width, d_height, d_width, d_depth,USB_type,vUSB,hUSB) {
  conn_depth = CAGE_DEPTH+rear_wall_thickness;
  hull()
  {
    translate([side_wall_thickness, rear_wall_thickness, top_bottom_wall_thickness])
    cube(size=[d_width, d_depth, d_height], center=false);
  }

  if (is_def(conn_height) && is_def(conn_width)) {
    hull() {
      translate([side_wall_thickness+hUSB + side_padding,

      rear_wall_thickness*3,

      -vertical_padding+top_bottom_wall_thickness//+vUSB
      ])

      port(d_height, d_width, d_depth,conn_height,conn_width,conn_depth,vUSB,hUSB);


      if (vUSB< max(conn_height,conn_width)) {
        translate([side_wall_thickness+hUSB + side_padding,

        rear_wall_thickness*3,
        (conn_height>=conn_width ? conn_width/2:conn_height/2)+
        -vertical_padding+top_bottom_wall_thickness //+vUSB
        ])
        port(d_height, d_width, d_depth,conn_height,conn_width,conn_depth,vUSB,hUSB);
      }
    }
  }
}



module port(d_height, d_width, d_depth,conn_height,conn_width,conn_depth,vUSB,hUSB) {
  hole_radius = conn_height>conn_width? conn_width/2 :conn_height/2;
  //ruler(3,20);
  rotate([90,0,0])

  hull()
  {
    translate([ conn_height<=conn_width ? conn_height/2-hole_radius:0,conn_height>conn_width ? conn_height/2-hole_radius:0,0])
    cylinder(r=hole_radius, h=conn_depth, center=false);


    translate([(max(conn_height,conn_width))/2,0,0, ])
    cylinder(r=hole_radius, h=conn_depth, center=false);
  }
}

module full_box(data_struct) {
  for (details=data_struct) {
    container(kv=details);
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

            //Internal function
            //Creates a list with the same structure of `list` with each of its elements replaced by 0.
            function _list_pattern(list) =
              is_list(list)
              ? [for(entry=list) is_list(entry) ? _list_pattern(entry) : 0]
              : 0;


//