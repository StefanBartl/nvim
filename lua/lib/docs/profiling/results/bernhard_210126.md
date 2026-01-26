23:41:10 msg_show.lua_print   require('lib.docs.profiling.LibInitProfiling.analyze').run() == Lazy_Init_Bernhard_210126 ==
23:41:10 msg_show.lua_print   require('lib.docs.profiling.LibInitProfiling.analyze').run() runs: 5
23:41:10 msg_show.lua_print   require('lib.docs.profiling.LibInitProfiling.analyze').run() module                                                   mean     median        min        max
23:41:10 msg_show.lua_print   require('lib.docs.profiling.LibInitProfiling.analyze').run() ------------------------------------------------------------------------------------------------
23:41:10 msg_show.lua_print   require('lib.docs.profiling.LibInitProfiling.analyze').run() lib.notify.@types                                       0.225      0.212      0.163      0.325
23:41:10 msg_show.lua_print   require('lib.docs.profiling.LibInitProfiling.analyze').run() lib.map                                                 0.266      0.217      0.191      0.379
23:41:10 msg_show.lua_print   require('lib.docs.profiling.LibInitProfiling.analyze').run() lib.fs.ignore.list                                      0.251      0.233      0.214      0.308
23:41:10 msg_show.lua_print   require('lib.docs.profiling.LibInitProfiling.analyze').run() lib.lazy                                                0.312      0.215      0.204      0.480
23:41:10 msg_show.lua_print   require('lib.docs.profiling.LibInitProfiling.analyze').run() lib.cross.fs._cwd                                       0.223      0.212      0.194      0.258
23:41:10 msg_show.lua_print   require('lib.docs.profiling.LibInitProfiling.analyze').run() lib.fs.path_shorten                                     0.257      0.236      0.227      0.309
23:41:10 msg_show.lua_print   require('lib.docs.profiling.LibInitProfiling.analyze').run() lib.notify                                              0.790      0.673      0.585      1.342
23:41:10 msg_show.lua_print   require('lib.docs.profiling.LibInitProfiling.analyze').run() lib.memo.lru                                            0.200      0.193      0.179      0.221
23:41:10 msg_show.lua_print   require('lib.docs.profiling.LibInitProfiling.analyze').run() lib                                                     1.016      0.928      0.860      1.359
23:41:10 msg_show.lua_print   require('lib.docs.profiling.LibInitProfiling.analyze').run() lib.memo                                                0.713      0.658      0.609      0.978
23:41:10 msg_show.lua_print   require('lib.docs.profiling.LibInitProfiling.analyze').run() lib.memo.memo                                           0.223      0.201      0.176      0.330
23:41:10 msg_show.lua_print   require('lib.docs.profiling.LibInitProfiling.analyze').run() lib.notify.safe                                         0.287      0.235      0.173      0.584
23:41:10 msg_show.lua_print   require('lib.docs.profiling.LibInitProfiling.analyze').run() lib.fs.is_subpath                                       0.338      0.311      0.274      0.413
23:41:10 msg_show.lua_print   require('lib.docs.profiling.LibInitProfiling.analyze').run() == Normale_Init_Bernhard_210126 ==
23:41:10 msg_show.lua_print   require('lib.docs.profiling.LibInitProfiling.analyze').run() runs: 5
23:41:10 msg_show.lua_print   require('lib.docs.profiling.LibInitProfiling.analyze').run() module                                                   mean     median        min        max
23:41:10 msg_show.lua_print   require('lib.docs.profiling.LibInitProfiling.analyze').run() ------------------------------------------------------------------------------------------------
23:41:10 msg_show.lua_print   require('lib.docs.profiling.LibInitProfiling.analyze').run() lib.fs.is_subpath                                       0.221      0.222      0.209      0.228
23:41:10 msg_show.lua_print   require('lib.docs.profiling.LibInitProfiling.analyze').run() lib.fs.is_dir                                           0.220      0.216      0.194      0.239
23:41:10 msg_show.lua_print   require('lib.docs.profiling.LibInitProfiling.analyze').run() lib.fs.relpath                                          0.214      0.206      0.197      0.257
23:41:10 msg_show.lua_print   require('lib.docs.profiling.LibInitProfiling.analyze').run() lib.fs.find_upward_dir                                  0.280      0.222      0.208      0.521
23:41:10 msg_show.lua_print   require('lib.docs.profiling.LibInitProfiling.analyze').run() lib.tables.dedup                                        0.255      0.225      0.196      0.405
23:41:10 msg_show.lua_print   require('lib.docs.profiling.LibInitProfiling.analyze').run() lib.memo.lru                                            0.184      0.184      0.170      0.197
23:41:10 msg_show.lua_print   require('lib.docs.profiling.LibInitProfiling.analyze').run() lib.terminal                                            0.262      0.223      0.203      0.350
23:41:10 msg_show.lua_print   require('lib.docs.profiling.LibInitProfiling.analyze').run() lib.buffer.is_markdown_buf                              0.218      0.180      0.169      0.325
23:41:10 msg_show.lua_print   require('lib.docs.profiling.LibInitProfiling.analyze').run() lib.notify.safe                                         0.224      0.231      0.172      0.272
23:41:10 msg_show.lua_print   require('lib.docs.profiling.LibInitProfiling.analyze').run() lib.buffer.insert_lines                                 0.203      0.182      0.177      0.288
23:41:10 msg_show.lua_print   require('lib.docs.profiling.LibInitProfiling.analyze').run() lib.tables.with                                         0.209      0.183      0.177      0.321
23:41:10 msg_show.lua_print   require('lib.docs.profiling.LibInitProfiling.analyze').run() lib.tables.array                                        0.205      0.200      0.172      0.253
23:41:10 msg_show.lua_print   require('lib.docs.profiling.LibInitProfiling.analyze').run() lib.tables.core                                         0.211      0.219      0.176      0.224
23:41:10 msg_show.lua_print   require('lib.docs.profiling.LibInitProfiling.analyze').run() lib.fs.ignore.list                                      0.236      0.241      0.210      0.260
23:41:10 msg_show.lua_print   require('lib.docs.profiling.LibInitProfiling.analyze').run() lib.tables.dict                                         0.188      0.185      0.166      0.207
23:41:10 msg_show.lua_print   require('lib.docs.profiling.LibInitProfiling.analyze').run() lib.tables.set                                          0.196      0.193      0.181      0.212
23:41:10 msg_show.lua_print   require('lib.docs.profiling.LibInitProfiling.analyze').run() lib.notify.resolve_log_level                            0.406      0.398      0.379      0.455
23:41:10 msg_show.lua_print   require('lib.docs.profiling.LibInitProfiling.analyze').run() lib.cross.fs._cwd                                       0.231      0.210      0.198      0.275
23:41:10 msg_show.lua_print   require('lib.docs.profiling.LibInitProfiling.analyze').run() lib.memo                                                0.581      0.590      0.537      0.620
23:41:10 msg_show.lua_print   require('lib.docs.profiling.LibInitProfiling.analyze').run() lib.strings                                             1.381      1.004      0.918      2.651
23:41:10 msg_show.lua_print   require('lib.docs.profiling.LibInitProfiling.analyze').run() lib.time.diff                                           0.267      0.275      0.239      0.277
23:41:10 msg_show.lua_print   require('lib.docs.profiling.LibInitProfiling.analyze').run() lib.normalize                                           0.321      0.302      0.228      0.483
23:41:10 msg_show.lua_print   require('lib.docs.profiling.LibInitProfiling.analyze').run() lib.memo.memo                                           0.176      0.172      0.165      0.194
23:41:10 msg_show.lua_print   require('lib.docs.profiling.LibInitProfiling.analyze').run() lib.strings.links                                       0.298      0.195      0.175      0.554
23:41:10 msg_show.lua_print   require('lib.docs.profiling.LibInitProfiling.analyze').run() lib.strings.patterns                                    0.355      0.181      0.170      0.992
23:41:10 msg_show.lua_print   require('lib.docs.profiling.LibInitProfiling.analyze').run() lib.strings.core                                        0.246      0.201      0.177      0.453
23:41:10 msg_show.lua_print   require('lib.docs.profiling.LibInitProfiling.analyze').run() lib.strings.remove_prefix                               0.202      0.181      0.169      0.290
23:41:10 msg_show.lua_print   require('lib.docs.profiling.LibInitProfiling.analyze').run() lib.notify.@types                                       0.191      0.174      0.161      0.253
23:41:10 msg_show.lua_print   require('lib.docs.profiling.LibInitProfiling.analyze').run() lib                                                    11.094     10.381      9.868     13.890
23:41:10 msg_show.lua_print   require('lib.docs.profiling.LibInitProfiling.analyze').run() lib.require                                             0.259      0.229      0.206      0.404
23:41:10 msg_show.lua_print   require('lib.docs.profiling.LibInitProfiling.analyze').run() lib.tables.functional                                   0.188      0.191      0.173      0.195
23:41:10 msg_show.lua_print   require('lib.docs.profiling.LibInitProfiling.analyze').run() lib.cross.platform.is_windows                           0.187      0.184      0.174      0.208
23:41:10 msg_show.lua_print   require('lib.docs.profiling.LibInitProfiling.analyze').run() lib.usercmd                                             0.210      0.210      0.202      0.219
23:41:10 msg_show.lua_print   require('lib.docs.profiling.LibInitProfiling.analyze').run() lib.autocmd                                             0.228      0.226      0.212      0.248
23:41:10 msg_show.lua_print   require('lib.docs.profiling.LibInitProfiling.analyze').run() lib.ui.hl                                               0.218      0.221      0.204      0.230
23:41:10 msg_show.lua_print   require('lib.docs.profiling.LibInitProfiling.analyze').run() lib.ui.hover_select                                     1.445      1.370      1.212      1.860
23:41:10 msg_show.lua_print   require('lib.docs.profiling.LibInitProfiling.analyze').run() lib.ui.hover_select.highlight                           0.205      0.199      0.195      0.222
23:41:10 msg_show.lua_print   require('lib.docs.profiling.LibInitProfiling.analyze').run() lib.ui.hover_select.navigation                          0.199      0.202      0.183      0.221
23:41:10 msg_show.lua_print   require('lib.docs.profiling.LibInitProfiling.analyze').run() lib.ui.hover_select.buffer                              0.232      0.200      0.183      0.324
23:41:10 msg_show.lua_print   require('lib.docs.profiling.LibInitProfiling.analyze').run() lib.ui.hover_select.config                              0.255      0.229      0.192      0.364
23:41:10 msg_show.lua_print   require('lib.docs.profiling.LibInitProfiling.analyze').run() lib.map                                                 0.331      0.296      0.210      0.460
23:41:10 msg_show.lua_print   require('lib.docs.profiling.LibInitProfiling.analyze').run() lib.strings.convert.hex_to_string                       0.286      0.194      0.178      0.580
23:41:10 msg_show.lua_print   require('lib.docs.profiling.LibInitProfiling.analyze').run() lib.nvim.simple_echo                                    0.184      0.189      0.172      0.194
23:41:10 msg_show.lua_print   require('lib.docs.profiling.LibInitProfiling.analyze').run() lib.lazy                                                0.203      0.203      0.187      0.220
23:41:10 msg_show.lua_print   require('lib.docs.profiling.LibInitProfiling.analyze').run() lib.cross.platform.is_wsl                               0.177      0.176      0.170      0.186
23:41:10 msg_show.lua_print   require('lib.docs.profiling.LibInitProfiling.analyze').run() lib.cross.platform.is_macos                             0.187      0.192      0.167      0.200
23:41:10 msg_show.lua_print   require('lib.docs.profiling.LibInitProfiling.analyze').run() lib.cross.platform.is_linux                             0.175      0.179      0.166      0.180
23:41:10 msg_show.lua_print   require('lib.docs.profiling.LibInitProfiling.analyze').run() lib.cross.platform.is                                   0.185      0.187      0.177      0.191
23:41:10 msg_show.lua_print   require('lib.docs.profiling.LibInitProfiling.analyze').run() lib.notify                                              0.677      0.662      0.558      0.857
23:41:10 msg_show.lua_print   require('lib.docs.profiling.LibInitProfiling.analyze').run() lib.cross.run                                           0.237      0.235      0.225      0.251
23:41:10 msg_show.lua_print   require('lib.docs.profiling.LibInitProfiling.analyze').run() lib.tables.safe                                         0.186      0.189      0.168      0.200
23:41:10 msg_show.lua_print   require('lib.docs.profiling.LibInitProfiling.analyze').run() lib.cross.copy_to_clipboard                             0.218      0.220      0.208      0.229
23:41:10 msg_show.lua_print   require('lib.docs.profiling.LibInitProfiling.analyze').run() lib.ui.hover_select.window                              0.218      0.204      0.193      0.269
23:41:10 msg_show.lua_print   require('lib.docs.profiling.LibInitProfiling.analyze').run() lib.fs.path                                             0.218      0.215      0.205      0.236
23:41:10 msg_show.lua_print   require('lib.docs.profiling.LibInitProfiling.analyze').run() lib.fs.path_shorten                                     0.266      0.225      0.204      0.343
23:41:10 msg_show.lua_print   require('lib.docs.profiling.LibInitProfiling.analyze').run() == UltraLazy_Init_Bernhard_210126 ==
23:41:10 msg_show.lua_print   require('lib.docs.profiling.LibInitProfiling.analyze').run() runs: 5
23:41:10 msg_show.lua_print   require('lib.docs.profiling.LibInitProfiling.analyze').run() module                                                   mean     median        min        max
23:41:10 msg_show.lua_print   require('lib.docs.profiling.LibInitProfiling.analyze').run() ------------------------------------------------------------------------------------------------
23:41:10 msg_show.lua_print   require('lib.docs.profiling.LibInitProfiling.analyze').run() lib                                                     0.304      0.277      0.260      0.393
23:41:10 msg_show.lua_print   require('lib.docs.profiling.LibInitProfiling.analyze').run() lib.map                                                 0.311      0.334      0.192      0.395
23:41:10 msg_show.lua_print   require('lib.docs.profiling.LibInitProfiling.analyze').run() lib.fs.ignore.list                                      0.305      0.302      0.207      0.385
23:41:10 msg_show.lua_print   require('lib.docs.profiling.LibInitProfiling.analyze').run() lib.lazy                                                0.255      0.232      0.200      0.350
23:41:10 msg_show.lua_print   require('lib.docs.profiling.LibInitProfiling.analyze').run() lib.cross.fs._cwd                                       0.235      0.198      0.191      0.311
23:41:10 msg_show.lua_print   require('lib.docs.profiling.LibInitProfiling.analyze').run() lib.fs.path_shorten                                     0.278      0.283      0.192      0.359
23:41:10 msg_show.lua_print   require('lib.docs.profiling.LibInitProfiling.analyze').run() lib.notify                                              0.781      0.822      0.654      0.861
23:41:10 msg_show.lua_print   require('lib.docs.profiling.LibInitProfiling.analyze').run() lib.notify.@types                                       0.239      0.237      0.195      0.290
23:41:10 msg_show.lua_print   require('lib.docs.profiling.LibInitProfiling.analyze').run() lib.notify.safe                                         0.212      0.200      0.184      0.248
23:41:10 msg_show.lua_print   require('lib.docs.profiling.LibInitProfiling.analyze').run() lib.fs.is_subpath                                       0.387      0.393      0.212      0.722
23:41:01 msg_showcmd <

