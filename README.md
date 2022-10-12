# qt4tests

This repository contains around 30,000 tests for XPath and XQuery, developed originally by the 
W3C XQuery and XSLT Working Groups, and subsequently expanded by members of the QT4CG W3C 
Community Group, and by individual contributors.

This started as a fork of the qt3tests repository published by W3C. The original tests have
been retained in their entirety, changing only when the results are no longer valid, and
many new tests have been added for new features proposed for the 4.0 versions of the
specifications. Efforts are made from time to time to pull new QT3 tests across into 
this repository when gaps are found in the test coverage.

The tests cover both XPath and XQuery.

There is metadata with each test to indicate its dependencies (which language versions and optional language 
features it requires), and its required environment (resources such as source XML files).

The metadata defines the expected results of each test, as a set of one or more assertions.

The test suite does not include test drivers for particular XQuery implementations.

Further information about the test suite is available in various documents in the "guide" directory.
