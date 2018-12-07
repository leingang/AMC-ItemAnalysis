Using AMC-ItemAnalysis
======================

In the GUI
----------

From the AMC GUI, go to the Reports tab and select one of the "Item Analysis"
options from the dropdown menu.  Click "Export" and after completion, open the
\ *exports*\  directory.  A file called \ *foo-item-analysis.ext*\  will be there,
where \ *foo*\  is the "short name" of your AMC project, and \ *ext*\  depends on 
which format you have chosen.

From the command line
---------------------

From the command line, you can execute

.. code-block:: console

 	auto-multiple-choice export --module ItemAnalysis_ext \
 	    --data project-data-dir \
        --fich-noms students-list.csv \
        --o output-file


Here \ ``ext``\  is one of \ ``LaTeX``\  or \ ``YAML``\ , depending on your desired output
format.

