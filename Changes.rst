Revision history for AMC-ItemAnalysis
=====================================

Unreleased Changes
------------------

Added
~~~~~

    * Change log is now formatted in ReSructured Test.  

    * Change log is now included in Sphinx docs.

Fixed
~~~~~

    * fixed a bug that caused free response problems with two-digit point
      values to elude detection.


Version 0.6, 2018-12-18
-----------------------

Deprecated
~~~~~~~~~~

    * Renamed a key :code:`histogram` to :code:`responses`.  This is a 
      backwards-incompatible change.

Added
~~~~~

    * Improved detection of open (free response) questions.

    * Improved box plot for open questions, with fancier style and plotting
      of outliers.

    * Various code improvements.


Version 0.5, 2018-12-07
-----------------------

Added
~~~~~

    * Open questions are now visualized with box-and-whisker plots instead of
      bar charts.  
        
    * Added documentation in Sphinx.

    * Mild GUI improvements.  Namely, inoperative controls are removed.

Fixed
~~~~~
        
    * Various bugs and typos fixed.


Version 0.4, 2017-11-27
-----------------------

Added
~~~~~

    * Questions are now sorted by database order.  This should be pretty close
      to catalog order.  Likely the most desired order.


Version 0.3, 2018-11-25
-----------------------

Added
~~~~~

    * Answer labels (A, B, C, ...) are now reported when available.

    * Some code cleanup.

Version 0.2, 2018-11-22
-----------------------

Fixed
~~~~~

    * Code refactoring to include separate export modules for separate
      formats.


Version 0.1, 2018-11-16
-----------------------

    * First working release.

