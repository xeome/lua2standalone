local template =
    [[

#define l_getlocaledecpoint() '.'

#define SQLITE_DEFAULT_FOREIGN_KEYS 1
#define SQLITE_ENABLE_RTREE 1
#define SQLITE_SOUNDEX 1
#define SQLITE_ENABLE_STAT4 1
#define SQLITE_ENABLE_UPDATE_DELETE_LIMIT 1
#define SQLITE_ENABLE_FTS4 1
#define SQLITE_ENABLE_FTS5 1
#define SQLITE_DEFAULT_RECURSIVE_TRIGGERS 1

/* core -- used by all */
#include "include/lapi.c"
#include "include/lcode.c"
#include "include/lctype.c"
#include "include/ldebug.c"
#include "include/ldo.c"
#include "include/ldump.c"
#include "include/lfunc.c"
#include "include/lgc.c"
#include "include/llex.c"
#include "include/lmem.c"
#include "include/lobject.c"
#include "include/lopcodes.c"
#include "include/lparser.c"
#include "include/lstate.c"
#include "include/lstring.c"
#include "include/ltable.c"
#include "include/ltm.c"
#include "include/lundump.c"
#include "include/lvm.c"
#include "include/lzio.c"

/* auxiliary library -- used by all */
#include "include/lauxlib.c"

/* standard library  -- not used by luac */
#include "include/lbaselib.c"
#if defined(LUA_COMPAT_BITLIB)
#include "include/lbitlib.c"
#endif
#include "include/lcorolib.c"
#include "include/ldblib.c"
#include "include/liolib.c"
#include "include/lmathlib.c"
#include "include/loadlib.c"
#include "include/loslib.c"
#include "include/lstrlib.c"
#include "include/ltablib.c"
#include "include/lutf8lib.c"
#include "include/linit.c"

/*
** Create the 'arg' table, which stores all arguments from the
** command line ('argv'). It should be aligned so that, at index 0,
** it has 'argv[script]', which is the script name. The arguments
** to the script (everything after 'script') go to positive indices;
** other arguments (before the script name) go to negative indices.
** If there is no script name, assume interpreter's name as base.
*/
static void createargtable (lua_State *L, char **argv, int argc, int script) {
  int i, narg;
  if (script == argc) script = 0;  /* no script name? */
  narg = argc - (script + 1);  /* number of positive indices */
  lua_createtable(L, narg, script + 1);
  for (i = 0; i < argc; i++) {
    lua_pushstring(L, argv[i]);
    lua_rawseti(L, -2, i - script);
  }
  lua_setglobal(L, "arg");
}

/* Define the script we are going to run */

const char my_prog[] = {
	thebytecodehex
  };

int
main(int argc, char **argv)
{
  int status, result, i;
  double sum;
  lua_State *L;

  L = luaL_newstate(); /* Create new Lua context */
  luaL_openlibs(L); /* Load Lua libraries */
  createargtable(L, argv, argc, 0);  /* create table 'arg' */

  status = luaL_loadbuffer(L,my_prog,sizeof(my_prog),"test");

  if (status) {
      /* If failed, error message is at the top of the stack */
      fprintf(stderr, "Loading error: %s\n", lua_tostring(L, -1));
      exit(1);
  }

  status = lua_pcall(L, 0, 0, 0);     /* call the loaded chunk */

  if (status) {
      /* If failed, error message is at the top of the stack */
      fprintf(stderr, "Runtime error: %s\n", lua_tostring(L, -1));
      exit(1);
  }

  lua_close(L);   /* Done with Lua */
  return 0;
}

]]

local insert = table.insert --optimizations
local byte = string.byte
local format = string.format

local inputlua = io.open(arg[1] or "input.lua", "rb")
local input = inputlua:read("*all")
inputlua:close()

local precompiled = string.dump(load(input),true)

local function convert(s)
    local converted = {}
    s:gsub(
        ".",
        function(a)
            local dec = byte(a)
            insert(converted, "0x" .. format("%x", dec))
        end
    )
    return converted
end

local bytecodetable = convert(precompiled)

local buffer = ""
for i = 1, #bytecodetable do
    if i ~= #bytecodetable then
        buffer = buffer .. bytecodetable[i] .. ","
    else
        buffer = buffer .. bytecodetable[i]
    end
end

local template = string.gsub(template, "thebytecodehex", buffer)
local outputC = io.open("output.c", "wb")
outputC:write(template)
outputC:close()

os.execute("gcc output.c -o "..(arg[2] or "output"))
