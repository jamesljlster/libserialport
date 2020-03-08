from os.path import exists

# Let definitions exists in config.h even their value is set to zero
persistent = ['PACKAGE_BUGREPORT',
              'PACKAGE_NAME',
              'PACKAGE_STRING',
              'PACKAGE_TARNAME',
              'PACKAGE_URL',
              'PACKAGE_VERSION',
              'SP_LIB_VERSION_AGE',
              'SP_LIB_VERSION_CURRENT',
              'SP_LIB_VERSION_REVISION',
              'SP_LIB_VERSION_STRING',
              'SP_PACKAGE_VERSION_MAJOR',
              'SP_PACKAGE_VERSION_MICRO',
              'SP_PACKAGE_VERSION_MINOR',
              'SP_PACKAGE_VERSION_STRING'
              ]

if not exists('config.h.in'):
    print('config.h.in does not exist!')
    exit()

# Auto generating config.h.cmake from config.h.in
src = open('config.h.in', 'r')
config = open('config.h.cmake', 'w')
config.write('/* config.h.cmake. Modify from config.h.in. */\n')
for line in src.readlines():

    # Replace #undef ... with #cmakedefine ...
    comp = line.split(' ')
    if comp[0] == '#undef':
        token = comp[1].strip('\n')
        if token in persistent:
            prefix = '#define'
        else:
            prefix = '#cmakedefine'
        line = '{} {} @{}@\n'.format(prefix, token, token)
    config.write(line)
