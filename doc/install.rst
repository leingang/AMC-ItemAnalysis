Installing AMC-ItemAnalysis
===========================

Via the GUI
-----------

To install this module from a distribution via the AMC GUI, select the hamburger
menu, then "Plugins", then "Install".  Select the compressed tarball using the
file picker.

Via the command line, from a distribution
-----------------------------------------

To install this module from a distribution via the command line, unpack it and
move the directory into your :code:`plugins` directory:

.. code-block:: console

	tar xzvf AMC-ItemAnalysis-x.x.x.tar.gz
	cp -r AMC-ItemAnalysis-x.x.x/ItemAnalysis ~/.AMC.d/plugins

From source
-----------

The master source code repository is hosted on 
`GitHub <https://github.com/leingang/AMC-ItemAnalysis`>.  You are welcome
to clone it and install from source.

After cloning, run the following commands:

.. code-block:: console

	perl Build.PL
	./Build
	./Build test
	./Build install

The necessary perl modules will be installed in
:code:`$ENV{HOME}/.AMC.d/plugins/ItemAnalysis/perl`, and documentation in
:code:`$ENV{HOME}/.AMC.d/plugins/ItemAnalysis/doc`.
