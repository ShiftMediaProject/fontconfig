fc_sources = [
  'fcatomic.c',
  'fccache.c',
  'fccfg.c',
  'fccharset.c',
  'fccompat.c',
  'fcdbg.c',
  'fcdefault.c',
  'fcdir.c',
  'fcformat.c',
  'fcfreetype.c',
  'fcfs.c',
  'fcptrlist.c',
  'fchash.c',
  'fcinit.c',
  'fclang.c',
  'fclist.c',
  'fcmatch.c',
  'fcmatrix.c',
  'fcname.c',
  'fcobjs.c',
  'fcpat.c',
  'fcrange.c',
  'fcserialize.c',
  'fcstat.c',
  'fcstr.c',
  'fcweight.c',
  'fcxml.c',
  'ftglue.c',
]

fcobjshash_h = cc.preprocess('fcobjshash.gperf.h', include_directories: incbase)
fcobjshash_gperf = custom_target(
  input: fcobjshash_h,
  output: 'fcobjshash.gperf',
  command: ['cutout.py', '@INPUT@', '@OUTPUT@'],
  build_by_default: true,
)

fcobjshash_h = custom_target('fcobjshash.h',
  input: fcobjshash_gperf,
  output: 'fcobjshash.h',
  command: [gperf, '--pic', '-m', '100', '@INPUT@', '--output-file', '@OUTPUT@']
)

lib_sources = [fc_sources, alias_headers, ft_alias_headers, fclang_h, fccase_h, fcobjshash_h, fcstdint_h]
lib_kwargs = {
  'include_directories': incbase,
  'dependencies': [deps, math_dep],
  'install': true,
}

if get_option('default_library') in ['both', 'shared']
  # Define FcPublic appropriately for exports on windows
  fc_c_shared_args = []
  if host_machine.system() == 'windows'
    fc_c_shared_args += '-DFcPublic=__declspec(dllexport)'
    fc_c_shared_args += '-DDLL_EXPORT'
  endif

  libfontconfig = both_libraries('fontconfig',
    lib_sources,
    c_shared_args: fc_c_shared_args,
    soversion: soversion,
    version: libversion,
    darwin_versions: osxversion,
    kwargs: lib_kwargs)
  libfontconfig_internal = libfontconfig.get_static_lib()
else
  libfontconfig = static_library('fontconfig', lib_sources, kwargs: lib_kwargs)
  libfontconfig_internal = libfontconfig
endif

fontconfig_dep = declare_dependency(link_with: libfontconfig,
  include_directories: incbase,
  dependencies: deps,
)

pkgmod.generate(libfontconfig,
  description: 'Font configuration and customization library',
  filebase: 'fontconfig',
  name: 'Fontconfig',
  requires: ['freetype2 ' + freetype_req],
  version: fc_version,
  variables: [
    'sysconfdir=@0@'.format(join_paths(prefix, get_option('sysconfdir'))),
    'localstatedir=@0@'.format(join_paths(prefix, get_option('localstatedir'))),
    'confdir=@0@'.format(fc_baseconfigdir),
    'cachedir=@0@'.format(fc_cachedir),
  ])
