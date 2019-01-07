Revision history for AMC-ItemAnalysis
=====================================

About this document
-------------------

This is a change log for AMC-ItemAnalysis_.

We adhere to `semantic versioning`_.  Each version number consists of
three numbers separated by dots.

* Increasing the first number indicates backwards-incompatible changes

* Increasing the second number indicates added behavior

* Increasing the third number indicates fixes to ensure expected behavior
  (i.e., bugfixes)

Since AMC-ItemAnalysis is a perl project, version are encoded as long
decimal numbers.  So version 1.3.12, if it existed, would be be indicated
by::

    $VERSION = '1.003012';

in the file :code:`lib/AMC/ItemAnalysis.pm`.

This document itself follows the guidelines from `Keep a Changelog`_.
Each version is given a section, with changes grouped by “impact.”
Note the use of past tense, indicative mood (as opposed to git commit
messages, which use present tense, imperative mood.)

* *Added* for new features.
* *Changed* for changes in existing functionality.
* *Deprecated* for once-stable features removed in upcoming releases.
* *Removed* for deprecated features removed in this release.
* *Fixed* for any bug fixes.
* *Security* to invite users to upgrade in case of vulnerabilities.

The top section, “Unreleased Changes,” is what will become the change log
for the next release.

Unreleased Changes
------------------

Added
~~~~~

* An action to the build script generates the plugin tarball.

* Documentation is now automatically generated at ReadTheDocs_.

.. _ReadTheDocs: https://amc-itemanalysis.readthedocs.io/

Changed
~~~~~~~

* Updated copyright year to current year (2019)

* Change log is now formatted in ReStructured Text.

* Change log is now included in Sphinx docs.

Fixed
~~~~~

* Fixed a bug in LaTeX formatting that caused undefined averages to
  be formatted as 0.00.

* Fixed a bug that caused free response problems with two-digit point
  values to elude detection.

* Fixed various typos

* Refactoring of library code to perlcritic_ “gentle” level

.. _perlcritic: https://metacpan.org/pod/distribution/Perl-Critic/bin/perlcritic


Version 0.6, 2018-12-18
-----------------------

Removed
~~~~~~~

* Renamed a key :code:`histogram` to :code:`responses`.  This is a
  backwards-incompatible change.  I believe such changes are allowable
  in pre-1.0 releases without changing the major version.

Changed
~~~~~~~

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

Changed
~~~~~~~

* Mild GUI improvements.  Namely, inoperative controls are removed.

Fixed
~~~~~

* Various bugs and typos fixed.


Version 0.4, 2017-11-27
-----------------------

Changed
~~~~~~~

* Questions are now sorted by database order.  This should be pretty close
  to catalog order.  Likely the most desired order.


Version 0.3, 2018-11-25
-----------------------

Added
~~~~~

* Answer labels (A, B, C, ...) are now reported when available.

Changed
~~~~~~~

* Some code cleanup.

Version 0.2, 2018-11-22
-----------------------

Changed
~~~~~~~

* Code refactoring to include separate export modules for separate
  formats.


Version 0.1, 2018-11-16
-----------------------

First working release.

.. _AMC-ItemAnalysis: https://github.com/leingang/AMC-ItemAnalysis
.. _`semantic versioning`: https://semver.org/
.. _`Keep a Changelog`: https://keepachangelog.com/
