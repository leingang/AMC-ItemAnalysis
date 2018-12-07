About Item analysis and this plugin
===================================

There are a couple of AMC reports that come in the box.  One of them is the ODS
(OpenOffice/LibreOffice spreadsheet) report.  It is quite good, in that it gives
not only students' scores question by question, and the frequencies of students'
responses for each question.  If you use AMC's randomizing feature, the report
unshuffles responses and puts them in the order they appear in the exam's
catalog.

From these tabs on the spreadsheet, you can answer questions like:

* Did students who did well on a certain problem do well overall?

* Which distractors were the most distracting?

* Did any of the questions turn out trickier than planned?

However, this may require adding formulas to the cells of the spreadsheet.
Moreover, the spreadsheet report will *not* be able to answer a question like:

* How did the students who fell for a particular distractor do overall on the
  exam?

* Is the exam *reliable*, in the sense that giving the same exam to a similar 
  group of students will product similar results?

This plugin was designed to provide feedback of this nature to the exam
designer.  It can inform decisions on which learning objectives are not being
met, as well as identify exam problems that may need to be revised before
setting on future exams.  Finally, the plugin provides visual as well as
numerical representations of these data.

What is item analysis?
----------------------

`Item analysis`_ is a topic in the field of psychometrics that seeks to analyze
how multiple “items” measure some characteristics.  The term “item” is meant
to be general and apply to any kind of measurement, but for our purposes an 
*item* is simply one question from a set (i.e., an exam).

.. _`Item analysis`: https://en.wikipedia.org/wiki/Item_analysis

In an item analysis, scores on the entire exam are broken down by responses to
each of the questions.  Usually, a regression analysis is calculated between the
score on a single question, and the total score on the exam.  The correlation
between individual items can also inform whether the exam is reliably measuring
students' mastery.

The difficulty of an question is determined by the students' average score on
the question, expressed as a fraction or percentage of the maximum possible
score.  Assuming the question score is nonnegative and there is no extra credit,
the question difficulty is a number between 0 and 1.  The closer the number is
to 1, the “easier” the students found the question.  This may be
counterintuitive, but it is how ScorePak reports item difficulty.

.. todo: find good references on this topic

How can item analysis be used to inform exam design?
----------------------------------------------------













