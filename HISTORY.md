Version 1.2.0 (2010-11-23)
==========================

* Notify user when absorbing overhead initially.

* DRY up the repetiton of Time.at(0) calculation.

Version 1.1.0 (2010-11-22)
==========================

* All *_{test,spec}_helper.rb files inside test/ and
  spec/ are now considered to be absorable overhead.

Version 1.0.2 (2010-10-16)
==========================

* All *_helper.rb files inside test/ and spec/
  were absorbed as overhead instead of just
  the test_helper.rb and spec_helper.rb files.

Version 1.0.1 (2010-10-16)
==========================

* Ensure that $LOAD_PATH reflects `ruby -Ilib:test`.

Version 1.0.0 (2010-10-15)
==========================

* Remove ability to install as a Rails plugin.

* Move logic from lib/ into bin/ to keep it simple.

* Rely on $LOAD_PATH in bin/ instead of relative paths.

* Display status messages for better user interactivity.


Version 0.0.2 (2010-10-11)
==========================

* Forgot to register bin/test-loop as gem executable.

* Revise Usage section into Invocation and Operation.


Version 0.0.1 (2010-10-10)
==========================

* First public release.  Enjoy!
