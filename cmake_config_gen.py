from os.path import exists

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
        line = '#cmakedefine {} @{}@\n'.format(token, token)
    config.write(line)
