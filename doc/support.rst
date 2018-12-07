
Support and Documentation
=========================


Locally-installed documentation
-------------------------------

After installing, you can find documentation for the modules with the
:code:`perldoc` command.  You just have to look in the right place.  You can
either add the plugin directory to perl's library path and search for the modules by their perl names, 

.. code-block:: console

     PERL5LIB=~/.AMC.d/plugins/ItemAnalysis/perl/ perldoc AMC::ItemAnalysis

or navigate straight to the `.pm` files.

.. code-block:: console

     perldoc ~/.AMC.d/plugins/ItemAnalysis/perl/AMC/ItemAnalysis.pm


Online documentation
--------------------

.. note::

     Coming soon!  Documentation built by Sphinx and continuously integrated at RTD.io.


Building documentation from source
----------------------------------

The module also supports the `Sphinx <http://sphinx-doc.org>`_ docmentation 
system (requires Python; see \ *reqirements-doc.txt*\ ). The \ ``librst``\  build
action will create reST files from the module's POD documentation, and then
the Sphinx documentation can be built.

.. code-block:: console

     ./Build librst
     cd doc/ && make html
     open _build/html/index.html


Support
-------

If you have a question, bug report, or feature request, please open an issue_ on
the `AMC-ItemAnalysis Github page`_.

.. _issue: https://github.com/leingang/AMC-ItemAnalysis/issues
.. _`AMC-ItemAnalysis Github page`: https://github.com/leingang/AMC-ItemAnalysis

