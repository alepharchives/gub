from gub import tools
import os
if 'BOOTSTRAP' in os.environ.keys (): from gub import target as tools

class File__tools (tools.AutoBuild):
    source = 'ftp://ftp.astron.com/pub/file/file-5.03.tar.gz'
    def configure_command (self):
        return (tools.AutoBuild.configure_command (self)
                + ''' LDFLAGS='-L%(system_prefix)s/lib %(rpath)s' ''')
    