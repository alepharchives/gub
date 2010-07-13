from gub import target

class Elixir (target.PythonBuild):
    source = 'http://pypi.python.org/packages/source/E/Elixir/Elixir-0.7.1.tar.gz'
    subpackage_names = ['']
    install_command = 'cd %(srcdir)s && python %(srcdir)s/setup.py install --prefix=%(tools_prefix)s --root=%(install_root)s'

    dependencies = [
        'python',
        'tools::setuptools',
        ]