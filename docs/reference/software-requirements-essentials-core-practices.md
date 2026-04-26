### 13

## Chapter 2

# Laying the Foundation

In the classical pure (and hypothetical) waterfall software development model, the
team accumulates a complete set of requirements for the product, designs a solution,
builds the entire solution, tests it all, and delivers it. We all know that approach
doesn’t work well in most cases.
Projects will vary in how much requirements work can, and should, be done up
front. Sometimes it’s possible to specify a good portion of the requirements for an
information system before getting too far into implementation. Complex products
with multiple hardware and software components demand careful requirements
engineering because the cost of making late changes is high. For applications that
change rapidly or lend themselves to incrementally releasing ever more capable soft-
ware versions, developing requirements just-in-time in small chunks is an effective
approach. Innovative apps may involve a lot of concept exploration, prototyping,
feasibility studies, and market assessment.
No single approach to the development life cycle or requirements work opti-
mally fits every situation. However, there are several interconnected activities related
to requirements that every team should perform at the beginning. This chapter
describes five essential practices that collectively provide a solid foundation for both
technical and business success:

```
Practice #1. Understand the problem before converging on a solution.
Practice #2. Define business objectives.
Practice #3. Define the solution’s boundaries.
Practice #4. Identify and characterize stakeholders.
Practice #5. Identify empowered decision makers.
```

### 14 Chapter 2 Laying the Foundation

```
Imagine that you worked for more than a year on a project that had executive sup-
port and high visibility. In your business analyst role, you performed the require-
ments elicitation, analysis, and specification. The development team built what the
stakeholders asked for and deployed the product on schedule. But just three months
later, the product is considered a failure and decommissioned. Why? Because it
didn’t solve the right problem.
Far too often, teams build and release requirements, features, and even entire
products that go unused because those teams didn’t fully understand the business
situation and the problems they were trying to solve. Understanding the problems or
opportunities that your solution will address aligns all participants on the core issues
and provides confidence that the solution will indeed achieve the desired outcomes.
```
## Business Problems

```
A business problem is any issue that prevents the business from achieving its goals or
exploiting an opportunity (Beatty and Chen 2012). A business problem can be small,
such as a user complaint that some task takes too long, which can perhaps be solved
by streamlining some functionality. Or it can be as large as organization-level busi-
ness challenges—spending too much money, not making enough money, or losing
money—that demand major projects or entirely new products.
Organizations launch initiatives to solve one or more business problems. Each
activity gets funded because management expects its business value to outweigh its
costs. However, those problems or opportunities often are neither explicitly stated
nor documented. Rather than presenting a clear problem statement, the executive
sponsor or lead customer might simply tell the team what to build. This can cause the
scenario described above: project success but product failure. If you don’t understand
the problem adequately, or if you begin with a specific solution in mind, there’s a
good chance that the team will solve only part of the problem—or perhaps none of it.
It’s a good idea to avoid presuming that either a presented problem or a presented
solution is necessarily correct. That initial presentation might come from a business
case, project charter, senior manager, or product visionary. But can you trust it as set-
ting the right direction for all the work that will follow?
When you’re presented with a stated problem, perform a root cause analysis
until you’re confident that the real issue and its contributing factors are well under-
stood (Tableau 2022). Then you can derive possible solutions that you know will
address those very issues. If you’re presented with a solution, explore this question:
“If < solution > is the answer, what was the question?” In other words, ask “Why do
```
## Practice #1 Understand the problem before converging on a solution.


### Practice # 1 : Understand the Problem before Converging on a Solution 15

you think that’s the right solution?” You might discover that the underlying issue
demands a different approach: possibly simpler, possibly more complex, possibly
more specific, possibly more general. You won’t know until you perform the analysis.

## Eliciting the Real Problems

A stakeholder might request a solution such as “Combine several systems into one,”
with the expectation that such a strategy would address multiple, unspecified objec-
tives. However, system consolidation could be overkill if a simpler answer is appro-
priate. If the problem is that you’re spending too much money on maintenance and
support for four existing systems, combining them could be the right approach.
However, suppose that the most pressing concern instead is that your users are
unhappy. A root cause analysis using the _5 Whys_ technique with the pertinent stake-
holders could sort all this out (Tableau 2022).
Root cause analysis involves working backward from a stated problem or a pro-
posed solution to identify the underlying problems and the factors that contribute
to them. Assessing those factors then leads to the appropriate solution choice. With
the 5 Whys technique, you ask questions like “Why is that a problem?” or “Why are
we not already achieving that goal today?” repeatedly until you unveil the compelling
issue that drove launching the initiative in the first place. The conversation between a
business analyst and a key stakeholder might go something like this:

```
Analyst: “You requested that we combine your four current systems into one. Why do
we need to combine them?”
```
```
Stakeholder: “Because our customers complain that they must keep signing in between
webpage clicks. It’s annoying. This is because they’re accessing different backend
systems that all have separate user accounts.”
Analyst: “Why is it an issue if your customers are complaining?”
```
```
Stakeholder: “According to our market research, 25 percent of our customers have left
us for the competition because of their frustrations with usability on our site.”
Analyst: “If that’s the case, why not just implement single sign-on to improve usability?”
```
```
Stakeholder: “That would help, but we’d still have to maintain and support all four systems.”
Analyst: “If we combined them, wouldn’t you still need the same number of support
people for the new system?”
```
```
Stakeholder: “We don’t believe so. The four current systems use different programming
languages. We need at least one engineer fluent in each language to support each sys-
tem, although there’s not enough work to keep them busy. By combining the systems
into one using a single language, we could free up the additional engineers to work on
other products.”
```

### 16 Chapter 2 Laying the Foundation

```
Analyst: “Ah, so it looks like you’re trying to solve multiple problems. You want higher
customer retention, and you also want to reduce support costs and free up staff by
using fewer technologies.”
```
```
By asking “why” several times in this conversation, the analyst now understands
that the stakeholder expects their proposed solution to address two significant con-
cerns. The request to combine several systems into one might indeed be the best
long-term strategy. However, an interim solution using single sign-on could appease
the disgruntled customers quickly, while the consolidation initiative works on the
larger concern of support and maintenance.
A root cause analysis diagram, also called a fishbone or Ishikawa diagram, is a
way to show the analysis results. Suppose the BA drills down into the first problem
the stakeholder brought up: losing frustrated customers. The BA could apply the
5 Whys technique to determine exactly why the customers are frustrated and then
draw a diagram like the one in Figure 2.1. The problem goes at the head of the “fish.”
Place the highest-level causes in the boxes on diagonal lines coming off the fish’s
backbone. Add contributing causes on the short horizontal lines from each diagonal.
Continue the exploration until you reach the ultimate, actionable root causes. Then
you can devise one or more solutions to address them.
```
```
Losing
Frustrated
Customers
```
```
Keep having to
log in
```
```
Can’t findwhat
they’re looking
for
```
```
Difficulties
navigating the
site
```
```
multipleuseraccounts
andpasswordsneeded
```
```
multiplebackend
systems
```
```
searchisn’t shared
across systems
```
```
disjointeduser experience
across UIs usingdifferent
backendsystems
```
```
systemsuse different
searchalgorithms,leading
to different results on
different pages
```
```
Figure 2.1 A root cause analysis (fishbone or Ishikawa) diagram example shows the factors
that contribute to the stated problem.
```
M02_Wiegers_C02_p013-044.indd 16 15/02/23 11:24 AM


### Practice # 1 : Understand the Problem before Converging on a Solution 17

Once you’ve identified the primary and contributing issues, consider all their
implications before committing to a solution. The requested or most apparent solu-
tion could be the wrong strategy. On one of Candase’s projects, the problem was that
the version of the commercial off-the-shelf (COTS) package the company used was
going end-of-life soon and the vendor would no longer support it. After that, any
production issue could have cost the company its entire business because it wouldn’t
have any vendor assistance. Nor could it currently make its own enhancements to
the vendor product. The obvious solution was to upgrade to the latest version of
the vendor’s product. However, the company would have had to pay the vendor high
service fees to resolve problems and add enhancements. Consequently, the company
considered both acquiring a new COTS package from a different vendor and build-
ing an in-house replacement as better solutions to both the initial end-of-life concern
and the additional issues.
Problem analysis can reveal other, unobvious challenges. You might confront con-
flicting problems from different stakeholders or be trying to solve multiple, disparate
problems with a single fix. As you explore the issues, look for situations where you
might need several solutions, rather than seeking a single silver bullet.

## Keeping the Business Problem in Focus

When the key stakeholders have agreed upon a clear understanding of the core busi-
ness concerns, consider writing a problem statement (Kyne 2022). A template like
this can be helpful (Compton 2022):

```
Situation Describe the background, context, and environment.
Problem Describe the business problems or opportunities as you now
understand them.
Implication Describe the likely results if the problem isn’t solved.
Benefit State the business value of solving the problem.
Vision Describe what the desired future state would look like.
```
A concise problem statement serves as the reference point for the rest of the
work. It feeds directly into crafting the specific business objectives that manage-
ment or your customers expect the solution to achieve (see Practice #2, “Define
business objectives”). The problem statement also helps the team make decisions
throughout the project. When prioritizing requirements, favor those items that are
the most critical or timely contributors to solving the highest-value problem (see
Practice #13, “Prioritize the requirements”). In the combine-several-systems-into-
one example above, implementing single sign-on to relieve customer frustration


### 18 Chapter 2 Laying the Foundation

```
would be a quicker fix than combining multiple systems and would address the
immediate concern of losing customers.
Whenever someone requests a new system capability, ask how it relates to the
business problems (see Practice #20, “Manage changes to requirements effec-
tively”). If you can’t tie each new requirement to any of the defined business prob-
lems, either there are more problems yet to explore or you don’t need the new
requirement.
Stakeholders often will propose a specific deliverable as a requirement: “Build
me product X or feature Y.” The stakeholder’s solution may indeed be the correct
one—but not necessarily. Take the time to thoroughly understand the real busi-
ness problem to ensure that the team focuses on achieving the proper outcomes.
If your analysis reveals that the real problem doesn’t quite match what you found
in a business case or other originating document, revise that document to match
the newly understood reality. That insight could profoundly change the project’s
direction.
```
## Related Practices

```
Practice #2. Define business objectives.
Practice #3. Define the solution’s boundaries.
Practice #13. Prioritize the requirements.
Practice #20. Manage changes to requirements effectively.
```
## Next Steps

```
1.If you haven’t already done so, talk with project leadership and key stakehold-
ers about why they’re undertaking your initiative to make sure you understand
the problem it is intended to solve.
2.Create a root cause analysis diagram for your core business problem, using a
technique like 5 Whys to discover both major and contributing causes.
3.Write a problem statement using the template described in this section.
4.Based on the problem or problems identified, assess whether your current solu-
tion concept will address them adequately. If not, either change the solution or
point out the risk that the current solution may not be sufficient.
```

### Practice # 2 : Define Business Objectives 19

Understanding the business problems and opportunities is an essential first step in
making sure the team focuses on the right concerns. The next step is to describe
exactly what the project sponsor or other important stakeholders expect the solution
to accomplish. If someone asks why your team is working on a particular initiative,
you should have a good answer.
Some people use the term _business requirement_ to refer to any requirement,
including bits of requested functionality, that comes from the business, but that’s not
how we use the term. We’re referring to information that explains why the organi-
zation has decided to undertake the project and what value they expect it to deliver
(Wiegers and Beatty 2013). Core elements of the business requirements include
statements of business opportunities and objectives, success metrics, and a vision
statement. Articulating the business requirements is an essential step in achieving
alignment among all stakeholders to create the right solution.

## Business Requirements

An organization undertakes an initiative to create or exploit a business opportunity,
satisfy a business need, or solve a business problem. Clearly stated business require-
ments build on the problem statement to specify the desired business outcomes,
identify indicators that will tell us when the problem is solved, and much more.
Business requirements appear at the top of the requirements model in Figure 1.1.
They provide the guiding directives for all the work that follows. If a project or
product fails to satisfy its business requirements, someone wasted a lot of time,
money, and effort.
Business requirements could originate from an executive who understands the
problem, a primary customer who recognizes a need, or a product visionary who
sees a market opportunity. Such people might already have established a business
case for the initiative, but they still might find it valuable to work with a BA to craft a
richer set of business requirements.
If you find yourself facilitating a discussion to explore a project’s business drivers
and justification, remember that the goal at that stage is not to accumulate an exten-
sive list of desired functionality. Instead, business requirements focus on _why_ launch-
ing this project or building that product is a good idea. The following questions
can stimulate a discussion that yields the relevant information (Business Analysis

## Practice #2 Define business objectives.


### 20 Chapter 2 Laying the Foundation

```
Excellence, n.d., Wiegers 2006). The website for this book offers a download with
these questions, and others, in the form of checklists.
```
- What business problem are you trying to solve or what business opportunity
    do you perceive?
- What’s the motivation for solving this problem or pursuing this opportunity,
    or what points of pain do you hope to relieve?
- What are your business objectives? Why aren’t you already achieving those
    desired outcomes?
- How would the proposed product provide value to the organization, the com-
    pany, your customers, or humanity as a whole?
- What would a highly successful solution do for you? Can you quantify its
    potential payoff?
- How could you judge the solution’s success?
- What could the business impact be if you _don’t_ pursue this solution?
- Which individuals, groups, products, systems, or projects could influence or be
    affected by this project?
- What are the timing goals or constraints for delivering a partial solution? A
    complete solution?
- If the organization unsuccessfully tried to solve this problem previously, why
    did the attempt fail and what should the team do differently this time?
- What assumptions are you making regarding the proposed initiative? What
    risks do you see associated with it?

```
Business requirements encompass several kinds of information. Many software
teams create a vision and scope document that contains the business requirements
using a template similar to the one shown in Figure 2.2 (Wiegers and Beatty 2013).
Other teams might store that information in a project charter, using a template
like the one in Figure 2.3 (Wiegers 2007). Both templates, with embedded guid-
ance text, are available for downloading from the website that accompanies this
book. The answers to the questions above let you populate various sections of
these templates.
```

### Practice # 2 : Define Business Objectives 21

**1. Business Requirements**
    1.1 Background
    1.2 Business Problem or Opportunity
    1.3 Business Objectives
    1.4 Success Metrics
    1.5 Vision Statement
    1.6 Business Risks
    1.7 Business Assumptions and Dependencies
**2. Scope and Limitations**
    2.1 Major Features
    2.2 Scope of Initial Release
    2.3 Scope of Subsequent Releases
    2.4 Limitations and Exclusions
**3. Business Context**
    3.1 Stakeholder Profiles
    3.2 Project Priorities
    3.3 Deployment Considerations

**Figure 2.2** _Suggested template for a vision and scope document (adapted from_ Software
Requirements, 3rd Edition, _by Karl Wiegers and Joy Beatty)._

1. Project Description
2. Business Objectives and Success Criteria
3. Stakeholders
4. Vision
5. Project Scope
6. Assumptions and Dependencies
7. Constraints
8. Milestones
9. Business Risks
10. Resources
11. Approvals

**Figure 2.3** _Suggested template for a project charter (from_ Practical Project Initiation _by
Karl E. Wiegers)._

Organizations that create commercial software products often write market
requirements documents that could include this business information. And any
organization could write a business case to justify investing in a new initiative. As
business analysis author Steven Blais (2012) points out:

```
All of these documents serve the same purpose: to provide the information necessary
for someone to make a decision to solve this business problem now, later, or never. The
overall goal of the business case is to minimize risk in decision-making.
```

### 22 Chapter 2 Laying the Foundation

## Business Objectives

```
Business objectives let you determine when a business problem is solved, a need is
fulfilled, or an opportunity is exploited. Business objectives can be financial or non-
financial, internal (operations) or outward facing (products), strategic or tactical.
While it’s easier to state vague goals, you should write your objectives to be specific,
realistic, and measurable. Otherwise, you can’t tell if you’ve achieved them.
Setting targets in the form of business objectives lets the decision makers define
the scope of work needed to achieve them. The objectives help ensure that the solu-
tion includes all the necessary functionality while avoiding extraneous features that
don’t contribute to the desired business outcomes.
Defining the business objectives up front drives the creation of the solution
concept. That concept then leads to activities to define the solution’s specific fea-
tures and attributes, a process called requirements elicitation. Suppose you have
a great idea for an innovative new product. You’re eager to dive into construc-
tion, maybe starting with a proof-of-concept prototype. That exploration is valu-
able, but before you begin to build the product for real, take the time to think
through why you want to build it and what you hope to accomplish: your business
objectives.
The simplest approach is to list the objectives you expect any solution to fulfill:
```
```
Grow the digital business from ~$1B to $10B in revenue with a 50 to 75 percent margin
by 2030.
Reduce the average time spent on document storage and retrieval from 10 hours to
2 hours per employee per week.
```
```
It’s better to quantify objectives by stating absolute goals, rather than percentage
changes relative to a current starting point (Beatty and Chen 2012). For example,
instead of this:
```
```
Increase market share in the Australasia region by 20 percent within 6 months.
```
```
state something like this:
```
```
Achieve a market share of at least 45 percent in the Australasia region by October 1, 2024.
```
```
Relative changes are hard to assess if the reference baseline value, dates, or measure-
ment method is not precisely stated and recorded.
A business objectives model permits a more thorough analysis for complex prob-
lems. This diagram is one of many in RML, the requirements modeling language
developed by Joy Beatty and Anthony Chen (2012). The business objectives model
visually links business problems to business objectives, their associated success
```

### Practice # 2 : Define Business Objectives 23

metrics, and the resultant solution concept (ArgonDigital 2022). A concise descrip-
tion of how to create a business objectives model is available from the website associ-
ated with this book. Figure 2.4 illustrates a partial business objectives model for a
hypothetical restaurant online ordering system designed to supplement taking phone
orders. We’ll see more about this system as we go along.
Modeling is particularly valuable when you have interwoven business problems
and objectives: One problem leads to an objective, which leads to a more detailed
problem, which leads to another objective, and so on, as in Figure 2.4. A more sophis-
ticated RML model, called the _objective chain_ , ties proposed solution features quan-
titatively to business objectives (Beatty and Chen 2012). The objective chain helps
you analyze which features will add the most value to the business or the solution’s
users and therefore are likely the most important to implement first.

```
Solution
Concept
Online menu
Online order
placement
Online order
payment
Usage
tracking
User
accounts
Activity
rating
```
```
Bus. Problem 1
50% of phone
requests to place
orders drop off on
hold, costing us
business.
```
```
Bus. Problem 3
Staffing to support
clusters of high-
demand phone
orders is not cost-
effective.
```
```
Bus. Problem 5
25% of customersdon’t come back
due to poor
ordering
experience.
```
```
Bus. Problem 4
Up to 50% of our
target market will
only place orders
online.
```
```
Bus. Objective 1
requests to placeConvert 95% of
orders into
submitted orders.
```
```
Bus. Objective 2 Increase monthly
revenue from
target market
to $28,000. 80% of customers Bus. Objective 5
come back within
1 month.
```
```
Bus. Objective 4
90% of target
market says
our order
placement channel
is acceptable.
```
```
Bus. Objective 3
Average cost to
place an order
doesn’t exceed
5% of average
order value.
```
```
Bus. Problem 2
Revenue from our
(18- to 35-year-olds)target market
is low.
```
**Figure 2.4** _A business objectives model links business problems, business objectives, success
metrics, and solution concepts._

## Success Metrics

_Success metrics_ let you judge progress and your solution’s contributions toward your
objectives. In some cases, the objective lends itself to direct measurement. The busi-
ness objective stated earlier—“Achieve a market share of at least 45 percent in the
Australasia region by October 1, 2024”—is one of those, assuming you can track
your market share as a function of time.
However, many business objectives are both lagging indicators (you can’t be sure
until the end) and potentially influenced by factors beyond your solution. In these


### 24 Chapter 2 Laying the Foundation

```
situations, you must use metrics that are proxies or surrogates that indicate whether
your solution is on track toward achieving the overall business objectives.
If your objective in the year 2023 is to grow revenue to $10B by 2030, you won’t
know for sure if you’ve achieved that for seven more years. Even if you do achieve
the goal, at least some of the growth could have been due to new marketing or sales
activities rather than your product. Interim success metrics, such as the number of
new customers or average order size, are indicators that could give you confidence
that your solution is doing what you hoped it would. Make sure that trends in the
surrogate metrics you select—the tracking indicators—are proportional to what
you’re really trying to achieve.
```
## Product Vision

```
A vision statement —another component of the business requirements—establishes
a high-level, strategic target to align all project participants toward the same out-
come. The vision statement succinctly summarizes the ultimate intent for the solu-
tion (Wiegers and Beatty 2013). In just a few sentences, the vision statement
articulates the essence of the problem, the nature of the proposed solution, its high-
level features, and its core benefits for certain stakeholders.
People sometimes lump together vision and scope, but they’re different things.
We think in terms of a product vision—which might never be fully attained—and
a project scope that defines what portion of the ultimate vision any specific pro-
ject or development cycle intends to realize. Along with the business objectives, the
vision statement describes how some aspect of the world will be better with the new
product: who’s the target market, what’s the product about, why is it better than the
current situation, and so on. This simple keyword template is helpful for writing a
vision statement (Moore 2014):
```
```
For [target customers]
Who [statement of the business need or opportunity]
The [name of the product or project]
Is 24 [type of product or project]
That [major product capabilities; core benefits it will provide; compelling
reason to buy the product or undertake the project]
Unlike [current business reality, alternative products, or the competition]
Our product [concise summary of the major advantages of this product over
the current reality or the competition]
```

### Practice # 2 : Define Business Objectives 25

The template helps people think through the vision statement elements and write
them in a consistent and concise pattern. As an illustration, here’s the vision statement
we wrote for this book, with the template’s keywords highlighted in **_bold italics_**.

```
For business analysts, product managers, product owners, requirements engineers,
user representatives, developers, testers, and other team members who are responsi-
ble for requirements development and management activities, Software Requirements
Essentials is a compact book that succinctly describes the twenty core requirements
practices that all software and systems projects should apply. Each practice is effi-
ciently summarized in a pragmatic style that lets the reader quickly understand why it is
important and how to begin applying it.
Unlike the many much longer, comprehensive texts on requirements and business
analysis that cover dozens of techniques in hundreds of pages, our product is a short
and highly readable book that focuses on just twenty essential practices in the areas
of laying the foundation for a successful project and requirements elicitation, analysis,
specification, validation, and management. This brevity and focus increase the appeal
to busy practitioners, who can quickly find the useful guidance they need, along with
pointers to other sources for further detail.
```
(As the reader—our customer—you are the ultimate judge of whether we deliv-
ered on this vision!)
Creating a vision statement is a collaborative activity, as everyone must be aligned
on the product vision. However, rather than asking several stakeholders to concoct
a joint vision statement, it’s illuminating to have them write their vision statements
independently using this template and then compare their results. This exercise can
reveal terminology differences, conflicting objectives, emphasis on different user
communities, and solution boundary issues that the participants must resolve.
As the team members make countless decisions about their work over time, they
should keep the problem statement, business objectives, success metrics, and vision
statement in mind. The implemented solution should deliver the value that lets the
organization achieve its business objectives. Clearly communicated business require-
ments set the stage for any information technology project to pay off.

## Related Practices

```
Practice #1. Understand the problem before converging on a solution.
Practice #3. Define the solution’s boundaries.
Practice #4. Identify and characterize stakeholders.
Practice #6. Understand what users need to do with the solution.
```

### 26 Chapter 2 Laying the Foundation

## Next Steps

```
1.If you don’t already have one, invite the key stakeholders who are driving the
project to agree upon a vision statement.
2.If your organization doesn’t have one yet, propose a template for a business
requirements document (or “container”) that’s tailored to suit the needs and
nature of your projects. If you do have a template already, compare it to the
content shown in Figures 2.2 and 2.3 and make any appropriate adjustments.
3.Work with the appropriate individuals to craft several quantitative, verifi-
able business objectives for your project. Confirm that the work underway or
planned aligns with achieving those objectives.
4.Define success metrics for each business objective that will reveal whether the
solution is moving in the direction of achieving those objectives.
5.If you have multiple interrelated business problems and objectives, draw a
business objectives model to show their connections.
```
## Practice #3 Define the solution’s boundaries.

```
When you start a new initiative, you have funding to solve one or more business
problems and a high-level concept of a possible solution. However, you might not
know exactly where to draw the line between what the solution should and should
not include. An important step in laying the foundation for a successful effort is to
establish that “what’s in, what’s out” boundary. You also need to know what changes
are needed in the forthcoming solution’s environment and where to make them.
Questions like these can help you figure all that out.
```
- Which business processes, functions, and events will be part of the solution?
    Which ones will remain outside it?
- Who will use or derive benefits from the solution? Who is excluded?
- Which software systems will be part of the solution? What will the interfaces
    between them look like?
- Where do each system’s responsibilities begin and end?
- What data sets, sources, and operations will be incorporated into the solution?
- How do we fit our solution into the rest of our universe?
- How do we know where to stop?


### Practice # 3 : Define the Solution’s Boundaries 27

Answering such questions allows the BA to clearly visualize and articulate which
software systems, hardware components, and manual operations lie within the cho-
sen solution’s scope.

## Refining the Solution Concept

To define the solution’s boundaries, the BA and the team must refine the intended
solution from a mere concept or feature list to a clear statement of what they will
build or enhance. Where you position the solution’s boundaries will depend on the
business objectives and the appetite for—and relative cost of—manual versus auto-
mated processes (Robertson and Robertson 2013).
Suppose your project is to implement an online ordering capability for a restaurant.
In the current state, the restaurant has only two information systems: a menu reposi-
tory and an order placement system. A customer gives their order verbally to a restau-
rant employee either on the phone or in person. The employee then enters the order in
the order placement system. The order placement system checks the menu repository
to ensure that all items in the order are available. If so, the order placement system gen-
erates a ticket for the cooks in the kitchen to prepare the order. In the case of a takeout
order, the employee who took the order gives the customer their best estimate of when
the food will be ready. There is no tracking of order status today.
The desired future state will incorporate online ordering, but that could mean
several things. The overarching solution—letting a customer place an order online
and then receive the food—remains constant regardless of how much automation
you implement. You will minimally need to introduce one new system: an online
ordering website. From there, you could define the solution’s boundaries in several
possible ways.

```
1.The simplest solution is a mainly manual process whereby the customer sub-
mits an order online, which is sent to a restaurant employee who then enters it
into the current order placement system.
2.A semiautomated solution could let customers order meals online and then
send those orders to the restaurant order placement system. However, custom-
ers would not be able to pay online or receive status updates following order
placement.
3.The ultimate, fully automated solution would let customers order all menu
items online, dynamically update the menu as items are purchased, per-
mit online payment and order placement to the restaurant, accept delivery
requests, and provide the customer with order updates. This would bring addi-
tional systems into the project’s scope beyond the core online ordering site:
payment processing, delivery services, and order tracking.
```

### 28 Chapter 2 Laying the Foundation

```
The solution boundary you select will be based on your business objectives, prod-
uct vision, constraints (such as security requirements for online payments), timeline,
and funding. Consider asking the key stakeholders to describe the smallest “thing”
to implement that would meet their objectives. Refining the initial simple solution
concept into a richer description will establish how much of the solution remains
manual and how much will be automated via new or existing systems.
Clear solution boundaries help the team evaluate new functionality requests to
determine to which system they should belong, if any. For the restaurant scenario, the
concise solution statement is: “A fully automated online ordering and payment pro-
cess with integration to third-party delivery and automated order tracking services.”
```
## Setting the Context

```
Once the BA has refined the solution concept, they must position each new system
within the company’s existing software environment. Start with any available docu-
mentation, such as a systems catalog or a system architecture diagram (Lucidchart
2022a). From there, the BA can create a context diagram for each new system being
built (Weilkiens 2007, Wiegers and Beatty 2013). Figure 2.5 shows a partial context
diagram for the restaurant’s new online ordering site. A context diagram begins with
the system of interest shown in a circle at the center of the diagram. The circle repre-
sents the system boundary. The context diagram provides no insight into the inter-
nals of that system, just its immediate environment.
A customer will interact with the online ordering site to view menu items, select
some items to build an order, and place their order with a valid payment method. To
implement the desired full automation, you’ll need to integrate the new online order-
ing site with the existing menu repository and restaurant order placement systems.
Additionally, you’ll need to connect with an external system for online payment pro-
cessing. Show all those external entities that will interact with the central system in
rectangles outside the circle. Finally, the context diagram shows the data that moves
between each entity and the system using arrows called flows. Label each flow with
a high-level description of the data: menu items, payment information, and so forth.
The context diagram delineates the scope of a single system, which could include
both automated and manual operations. External entities outside the circle aren’t
part of that system, although they could be built as part of the same project. Each
external system would have its own context diagram to show its system boundary
and environment. As the project progresses and the expectations of a release are bet-
ter understood, the BA may discover more external entities to which the system will
connect.
As with other BA techniques, the context diagram is a useful tool to engage
with stakeholders to reach a common and accurate mindset. The resultant diagram
```

### Practice # 3 : Define the Solution’s Boundaries 29

formalizes the system boundaries; creating or reviewing it collaboratively can expose
potential issues and help resolve misunderstandings.

## Expanding the Ecosystem

A context diagram identifies the user classes, hardware devices, and any other sys-
tems that interact with a product. However, it only shows the direct connections
between our system of interest and those external entities. An _ecosystem map_ goes
beyond the immediate context of a single system (Beatty and Chen 2012). It depicts
the overall solution view, including all systems in a given application domain—or
even an entire company—along with the high-level data flows between them. The
ecosystem map can help you understand any upstream or downstream impacts you
are making on data that the systems exchange.
Figure 2.6 shows an ecosystem map for the restaurant online ordering example.
It shows that the desired solution of full automation extends beyond the new online
ordering site and its immediate connections. The solution also will involve enhance-
ments to the existing restaurant order placement system to integrate with a new
order tracking system and an external third-party delivery application.

```
Menu
Repository
```
```
Restaurant
Order
Placement
```
```
Online
Payment
Processing
```
```
order confirmation,
order updates
```
```
order,
payment info
```
```
Online
Ordering
Site
```
```
Customer
```
```
menu items,
payment confirmationorder confirmation,
```
```
menu updates
```
```
order
```
```
payment
confirmation
```
```
payment info menu items
```
**Figure 2.5** _A context diagram shows the immediate environment of the restaurant’s new
online ordering site._


### 30 Chapter 2 Laying the Foundation

```
To create an ecosystem map, first list the systems in your solution domain. If you
don’t have a full system list, start with your system of interest and its direct connec-
tions. From there, look at each connecting system and its additional connections,
showing each system in a box. Move outward until you’ve covered the entire solution
domain.
Next, examine the systems to determine which of them exchange data. Look for
both synchronous (API calls) and asynchronous (message-based) integrations, as
well as file-based and direct database connections. Link the interrelated systems with
arrows indicating each data flow’s direction, as in the context diagram.
Complete the ecosystem map with a high-level description of the data that’s
shared through each connection. Combining the ecosystem map with the context
diagram shows both who is using the target system and the overall multisystem
view. An ecosystem map has good reuse potential for multiple projects and products
within an organization.
```
## Applying the Solution’s Boundaries

```
Once the BA and the team have defined the solution’s boundaries, they’ll be valuable
throughout the project’s life for scope definition, product roadmap definition, and
release planning. An extensive solution with full online ordering automation could
```
```
Online
Ordering Site
```
```
Online
Payment
Processing
```
```
Emailand
Text
Exchange
```
```
Order
Tracking
```
```
Third-Party
Delivery
```
```
payment info
confirmationpayment
```
```
order updates
```
```
delivery updates
```
```
Menu
Repository
```
```
menu items
menu updates
```
```
order updates
```
```
order
```
```
order confirmation,orderupdates order
```
```
order updates
delivery updates
```
```
Restaurant
Order
Placement
```
```
menu updates
```
```
menu items
```
```
delivery request
```
```
Figure 2.6 An ecosystem map shows how the restaurant’s current and future systems are
interconnected.
```

### Practice # 3 : Define the Solution’s Boundaries 31

Analyze each interface in an ecosystem map or context diagram to elicit exter-
nal interface requirements and constraints. For example, a third-party delivery sys-
tem likely has defined technical interfaces to which all users must conform. Those
interfaces constrain how the order placement system can integrate to the third-party
delivery product.
As new requirements arise, use the product vision, business objectives, and solu-
tion boundaries to determine whether each requested requirement should be imple-
mented. Suppose you get a request to integrate the order placement system with one
or more third-party ordering systems. Based on the current solution boundaries, that
capability is out of scope. It could be funded by a separate project. Alternatively, man-
agement might opt to broaden this project’s scope to address that additional need,
providing extra resources and time as needed (this is just a little joke we like to make).
Clearly defined solution boundaries and models of the connections help the BA
explain the need for certain functionality. Perhaps someone asks why the online
ordering site needs to update the menu repository, as shown in Figure 2.6. Since the
order placement system updates the menu repository during meal preparation, must
the online ordering site do it as well?
Well, if the ordering site doesn’t update the menu repository as soon as a customer
places an order, the menu on the website would be out of date, even if only briefly,

**Table 2.1** _Example release objectives_

**Release Release objective**
1 Build online ordering site and integrate it with existing menu repository and restaurant
order placement systems.
2 Add online payment processing to permit payment at time of order placement.
3 Implement order tracking and integrate with third-party delivery services.
4 Provide automated order and delivery updates to the customer.

take many months to complete. In iterative projects, the team will break the full
implementation into a series of releases or development increments, each of which
provides a useful portion of the overall solution. This strategy allows the business to
begin achieving its objectives before all the functionality is completed.
To quickly attract those customers who will place orders only online, the team’s
first release might include building just the online ordering site and integrating it
with the existing menu repository and order placement systems. The customer would
still have to pick up and pay for the order in person. Subsequent releases would incre-
mentally add functionality to the overall online ordering process. Table 2.1 shows
how the ultimate solution could be realized through several development increments
and product releases.


### 32 Chapter 2 Laying the Foundation

```
having no knowledge of current inventory levels. Suppose someone ordered the last
one of some item, making it out of stock even though the meal was not yet prepared.
If the menu repository weren’t updated immediately, another customer could then
order that same item but not receive it, thereby annoying them. (Karl has had this
experience; he was annoyed.) Using the business objectives, solution boundaries, and
ecosystem map, the BA can defend why each requirement belongs in the solution.
You can also use the solution’s boundaries to decide which product component
should own which pieces of functionality. Allocating requirements appropriately to
systems, subsystems, and people is important both for business information systems
and for complex products that include both hardware and software elements. Ana-
lyzing data inputs and outputs indicates which systems or functions produce certain
data objects and which consume them.
By refining the solution concept to a defined set of components and boundaries,
the BA can ensure that the solution scope—including new development, enhance-
ments, integrations, and manual operations—is well understood and communicated
to all stakeholders.
```
## Related Practices

```
Practice #2. Define business objectives.
Practice #8. Assess data concepts and relationships.
```
## Next Steps

```
1.If you haven’t already done so, work with your stakeholders to make sure
everyone understands the boundaries around the solution the team is creating.
Refer to your business objectives and identify the minimal change needed to
meet those objectives.
2.Create a context diagram and an ecosystem map to get the full view of your
solution’s components and boundaries. Look for existing examples of these
artifacts that can be updated as appropriate.
3.Use the context diagram and ecosystem map to evaluate your currently
requested functionality. Confirm that it really belongs to your current project
based on the defined solution’s boundaries. If it does not, defer those requests
to a future project or redefine the solution’s boundaries.
```

### Practice # 4 : Identify and Characterize Stakeholders 33

```
4.Examine the ecosystem map to identify groups or systems that don’t connect
directly to your product but could require changes because of the data that
your solution exchanges with other related systems. Work with the owners of
those connected systems to make sure everyone understands and commits to
the necessary modifications.
```
Every project has people who care about it: its stakeholders. A _stakeholder_ is an indi-
vidual or group that is actively involved in a project, is affected by it, or can influence
its direction. The interests of all the stakeholders intersect in the requirements activi-
ties (Wiegers 2022).
Consultant and author Tim Lister describes project success as “meeting the set
of all requirements and constraints held as expectations by key stakeholders.” Those
stakeholders provide the information a BA needs to understand the business problem
or opportunity. The right stakeholders can describe the current state and the changes
needed to migrate to an improved future state. Their input allows a BA to define the
capabilities and characteristics of an appropriate solution and to validate the pro-
posed solution.
It’s important to identify the project’s significant stakeholder groups early on
and determine how best to engage with them. Overlooking stakeholders can lead to
requirements gaps or unknown constraints that are disruptive when they’re finally
discovered. Certain stakeholders set the project’s direction and hold authority over
major decisions. Others don’t provide any input; they merely get what they get. Most
stakeholder groups lie somewhere between these extremes along a spectrum of influ-
ence and engagement. It’s important to identify those stakeholders who are most
heavily involved with making various decisions (see Practice #5, “Identify empow-
ered decision makers”).
Simply identifying and characterizing your stakeholder categories isn’t suffi-
cient. You also must select appropriate representatives of those groups to partici-
pate in requirements activities. Even then, stakeholder issues can cause requirements
problems. Missing roles, absent participants, and ineffective surrogates can lead to
requirements errors that you’ll need to fix later at greater expense.

## Practice #4 Identify and characterize stakeholders.


### 34 Chapter 2 Laying the Foundation

## The Quest for Stakeholders

```
A project’s business objectives and vision statement provide a starting point in your
stakeholder search. The first sentence of the sample vision statement from Practice
#2, “Define business objectives,” began as follows:
```
```
For business analysts, product managers, product owners, requirements engineers, user
representatives, developers, testers, and other team members who are responsible for
requirements development and management activities....
```
```
The list of people following the opening keyword For is an initial set of stakeholders.
As you continue the hunt, cast a wide net to reduce the chance of overlooking a sig-
nificant group. To save time, you might begin with a stakeholder catalog accumulated
from previous projects. Scan through that catalog to see if any of those same groups
are relevant to your current project. Building a stakeholder catalog incrementally from
one project to the next provides a valuable reusable asset to use as a starting point the
next time. An organization chart can help you detect other potential stakeholders.
You can also refer to a comprehensive list of typical stakeholder categories to look
for possibilities, like the one in Table 2.2 (Wiegers and Beatty 2013). Some stakehold-
ers are found within the development team, others work elsewhere in the developing
organization, and still more lie somewhere outside the developing organization.
Some stakeholders may be primarily interested in the project itself, others in the
solution the project delivers. For instance, users don’t care much about how a product
is built if it lets them do their work efficiently and without much frustration. When
you’re searching for stakeholders, consider questions like these (Leffingwell 2011).
```
- Who has influence or control over the project’s budget and schedule?
- Who can articulate the project’s business objectives?
- Who will be using the product directly? Indirectly?
- Who is responsible for other systems or projects that yours will affect or will
    affect yours?
- Who could have legal, compliance, regulatory, or process influence?
- Who manages the business relationships with customers, suppliers, and
    contractors?
- Whose business processes would the system affect?
- Who is expected to supply any data needed by the solution?
- Who would know about any pertinent project, product, or process constraints?

```
As you accumulate a stakeholder list, ask other stakeholders to review it. They often
know of someone else who should be included.
```

### Practice # 4 : Identify and Characterize Stakeholders 35

**Table 2.2** _Some common potential software project stakeholders and where they’re likely to
be found_
**Location Category**
Development team Application architect

```
Business analyst
Data analyst
Database administrator
Database designer
Developer
Documentation writer
Hardware engineer
```
Infrastructure analyst
Product manager
Product owner
Project manager
Quality assurance
Software designer
Tester
User experience designer
Inside the
developing
organization

```
Company owner
Compliance
Contract manager
Development manager
Executive sponsor
Information architect
Infrastructure support
Installer
Legal
Maintainer
Manufacturing
```
```
Marketing
Operations support
People responsible for connected systems
Portfolio architect
Process analyst
Program manager
Project management office
Sales
Security analyst
Training
```
Outside the
developing
organization

```
Auditor
Beta tester
Business management
Certifier
Compliance auditor
Consultant
Contracting office
Contractor
Customer management
Direct user
General public
```
```
Government agency
Indirect user
Materials supplier
Procurement staff
Purchaser
Regulatory body
Shareholder
Software supplier
Subject matter expert
Venture capitalist
```

### 36 Chapter 2 Laying the Foundation

## Stakeholders, Customers, and User Classes

```
People sometimes use the terms stakeholder , customer , and user interchangeably.
However, as you can see from Table 2.2, only certain stakeholders are customers, and
only certain customers will use the product. Some customers present solution
requirements, evaluate candidate products, supply data, or acquire a product but
never touch it themselves. Other nonusers of an information system still could be
stakeholders because business operations include manual actions as well as com-
puter tasks. A software system could have an impact on those manual operations.
Steven Blais (2012) refers to this set of both system users and affected nonusers col-
lectively as process workers.
Don’t regard your users as a monolithic group: “the user.” Nearly every product
has multiple—sometimes many— user classes. Members of various user classes may
differ in the features they use, tasks they perform, frequency of use, location, access or
privilege level, education or experience level, and in other ways. Many users will inter-
act with an information system directly. Indirect users provide inputs to it or receive
outputs from it but don’t interact with the system themselves. User classes could also
be other software systems or hardware devices that obtain services from your product.
Treat each user class as a separate stakeholder subcategory because the BA will
need to work with representatives of each class to understand their needs. Some over-
lap of requirements across user classes is common.
Certain user classes may be favored over others because their interests more
strongly coincide with the initiative’s business objectives (Gause and Lawrence
1999). Those groups should carry more weight than others regarding decisions
about requirements priorities, proposed requirement changes, and similar matters.
Identifying the favored user classes helps you resolve priority and functionality con-
flicts that arise across classes.
As an example of different user classes for a product, consider a hypothetical
publishing platform called Speak-Out.biz, on which authors can post articles on any
topic they like. Readers can view articles, comment on articles, and subscribe to their
favorite authors. Authors can submit their articles to any of numerous publications
that aggregate articles on diverse themes. Editors select whether to include submit-
ted articles in their publications. This brief description names or implies several user
classes for Speak-Out.biz:
```
- Author
- Reader
- Publication Editor
- Administrator


### Practice # 4 : Identify and Characterize Stakeholders 37

Each type of user has various tasks they wish to perform on the platform, cer-
tain usage privileges, and particular functional and quality expectations of the prod-
uct. If you were launching such a publishing platform, you’d want to characterize
the various user classes and then seek suitable representatives to understand each
group’s requirements and constraints. We’ll revisit Speak-Out.biz in some upcoming
practices.

## Characterizing Stakeholders

Early in the project, perform an analysis to understand who your stakeholders are,
each group’s interests in the project, their influence over it, and their expectations
and concerns (Gottesdiener 2005, Lucidchart 2022b). Questions like the following
will provide a rich understanding of each stakeholder group (McManus 2005,
Wiegers 2022).

- Who are they? How many of them are there?
- Where are they? What’s the best way to communicate with them?
- What roles do they play with respect to the project?
- How much power or influence do they have over the project?
- What are their interests, concerns, and fears?
- What benefits do they wish to receive from the product? What are their needs,
    expectations, and success criteria?
- What information can they provide regarding operations, technology, data, or
    other areas?
- What do they need to know about the project?
- For users, how will they use the product?

Table 2.3 illustrates a simple template with information to record for each
stakeholder profile, using one of the stakeholders from Speak-Out.biz as an exam-
ple. Your organization could accumulate these profiles from multiple projects
into a reusable, enterprise-level stakeholder catalog. Stakeholder profiles go into
section 3.1 of the vision and scope document template, which was shown in
Figure 2.2. If you already have a stakeholder catalog, you can just point to the
appropriate entries in that section of the vision and scope document rather than
duplicating the information.


### 38 Chapter 2 Laying the Foundation

```
With your stakeholder catalog in hand, identify individuals who can accurately
represent the interests of each stakeholder group and agree upon how they will
engage with the BA and other team members. Make sure those representatives will
have the bandwidth to contribute to the initiative in the necessary time frame. It can
be more challenging to find and interact with stakeholders outside the developing
organization than with internal people. However, their participation may be critical
because of their authority, responsibilities, control over resources, or political, legal,
or regulatory influence.
Consider whether each group is a collaborative partner in development, can make
final decisions about certain aspects of the project, should be consulted for their
expertise on specific issues, or just needs to be informed of progress and decisions
that affect them (Leffingwell 2011). Some teams create a RACI matrix to identify
stakeholder roles and their responsibilities with respect to the project. The RACI
matrix shows which stakeholders are R esponsible, A ccountable, C onsulted, or
I nformed (Morris 2022).
Make sure you know who is speaking for each stakeholder community. For the vital
role of user representative, the product champion approach works well in many situ-
ations (Wiegers and Beatty 2013). A product champion is a designated and empow-
ered key representative of a specific user class. Product champions work closely with
BAs through interviews, workshops, prototype evaluations, and other collaborative
activities to elicit and validate requirements. A product champion serves as the literal
voice of the customer for a specific category of users. If you can’t engage with actual
user representatives directly, someone must still speak for the needs of each user class
as a proxy.
The time spent on stakeholder analysis early on might seem like a distraction
from real software work. Not so—it is the real work of ensuring that you engage the
right participants in a collaborative effort that builds a solid base for success.
```
```
Table 2.3 Portion of a sample stakeholder profile for Speak-Out.biz
Stakeholder Roles Interests Influence Needs Concerns
Author Writes, edits,
and posts
articles; tracks
statistics and
earnings
```
```
Interest =
High; reaching
a broad
audience;
generating
revenue from
articles
```
```
Power = Low:
can request
features
and report
problems or
abuse
```
```
Easy-to-use
text editor;
submitting
articles to
publications;
customizable
statistics
reports
```
```
Integrity of
posted articles;
long-term
stability of
platform
```

### Practice # 5 : Identify Empowered Decision Makers 39

## Related Practices

```
Practice #1. Understand the problem before converging on a solution.
Practice #2. Define business objectives.
Practice #3. Define the solution’s boundaries.
Practice #5. Identify empowered decision makers.
Practice #6. Understand what users need to do with the solution.
Practice #13. Prioritize the requirements.
```
## Next Steps

```
1.Examine Table 2.2 for any stakeholders for your initiative that might have been
overlooked.
2.Characterize each of your significant stakeholder groups so that you can iden-
tify appropriate representatives and agree on how to engage with them.
3.Set up a template format for a stakeholder catalog and begin populating it with
your stakeholder information for this project. If your organization works on
projects that have recurrent stakeholders, establish a mechanism to maintain
and reuse this catalog on future initiatives.
4.Identify your significant user classes. Note any user classes that are favored
over others. Make sure it’s clear who presents the requirements, constraints,
dependencies, and risks for each user class. Confirm that those individuals
have the knowledge and authority to perform their representation role well.
```
## Practice #5 Identify empowered decision makers.

```
Every project faces a continual stream of decisions large and small. Individual
team members can make many decisions locally and informally; other issues have a
far broader impact. Making a considered decision about a requirements issue often
demands obtaining input from multiple sources, having appropriate stakeholders
assess the options, and communicating the outcome—and the reasons for it—to
```
M02_Wiegers_C02_p013-044.indd 39 17/02/23 2:33 PM


### 40 Chapter 2 Laying the Foundation

```
all affected communities. Common classes of requirements-related decisions
include these:
```
- Resolving conflicting requirements within a user class and across user classes
- Prioritizing requirements of various types
- Resolving conflicting priorities among different stakeholders
- Adjusting priorities as new needs come along and project realities change
- Making trade-off choices between conflicting quality attributes
- Defining the number of development increments or releases and the scope of
    each one
- Determining which new or changed requirements to incorporate into develop-
    ment plans (product backlog management)
- Deciding when and how to modify the scope of a planned development incre-
    ment, a product release, or the entire project

```
Some organizations—and individuals—are better at making decisions than oth-
ers. Karl used to work at a company in which decision-making was sluggish because
no one wanted anybody to be uncomfortable with the outcome. That’s not practi-
cal. As a colleague pointed out, “This company is not a democracy.” Someone must
choose among the options and set directions so that everyone can work toward the
shared objectives. It was frustrating to deal with managers who vacillated, never
reaching closure on issues that were appropriate for their level. Karl had more respect
for managers who would make a decision, even if he didn’t always agree with it.
It’s important to determine who the decision makers will be for various require-
ments issues. The initiative’s leaders should do this before the group confronts their
first significant decision. Identifying the decision makers ensures that decisions can be
made at the lowest possible level. Issues are resolved more quickly when decisions are
made locally than when small matters are escalated to a higher level. Each group also
should agree upon how they will reach their conclusions—that is, which decision rule
or rules they’ll apply—and the path forward if they’re unable to resolve an issue.
```
## Who Makes the Call?

```
The right people to make each category of decision depends on the situation. Major
scope issues that affect schedules, resources, and existing commitments will involve
senior managers or executives. Those managers could be in the developing organiza-
tion, a customer organization, marketing, or combinations of those. A single
```

### Practice # 5 : Identify Empowered Decision Makers 41

requirement change could have a big ripple effect if it forces revisions to multiple
interconnected elements. Representatives from all the affected components need to
know about the decision outcome, even if they don’t all participate in making it.
Identifying the decision makers for requirements issues is a part of stakeholder
analysis. Input from those stakeholders whose interests align most closely with the
project’s business objectives, such as favored user classes, should carry the most
weight. Stakeholders who impose constraints—including scope, resource, regulatory,
legal, business policy, or technical restrictions—may override functionality requests
from other groups that conflict with the constraints. Agreeing on which stakeholders
contribute most heavily to which important decisions helps the group reach conclu-
sions more quickly and perhaps with less rancor.
Each decision-making group should identify a decision leader to coordinate their
activities. The idea is not to add bureaucratic overhead, but rather to provide clear
lines of responsibility, authority, and accountability. A group of people might think
they have the authority to make decisions about a certain range of issues. But if
someone else can override their choices, then, in effect, that group is merely an advi-
sory body; the other “someone” is the ultimate decision maker. The decision leader
makes all those roles and responsibilities clear to avoid delays, uncertainty, revisited
decisions, and hard feelings.
On typical agile projects, the product owner (PO) is the decision leader for
requirements-related issues. This is consistent with the PO’s responsibilities for cre-
ating, prioritizing, and managing items in the product backlog to guide the team
toward achieving the desired outcome (Agile Alliance 2022a). The PO’s central role
is sometimes described as being the “single wringable neck” in case things go awry
(Bernstein 2016). We hope that’s meant to be tongue in cheek.
One large project, for which Karl was the lead BA, assembled a user requirements
team with representatives from four user classes: product champions, as described in
Practice #4, “Identify and characterize stakeholders.” The largest and most diverse
user class required additional representatives from several subgroups to cover the
breadth of needs. When requests from the subgroups didn’t agree, the product cham-
pion for that overall user class was fully empowered to make the choice. And he did!
The other participants respected the product champion’s experience, wisdom, and
conclusions. Having a few carefully selected and empowered user representatives
who could make requirements decisions on behalf of their respective communities
made life much easier for the three BAs.

## How Do They Decide?

Too often, when people begin to collaborate on some initiative, they don’t discuss
exactly _how_ they’re going to work together. An important—and sometimes


### 42 Chapter 2 Laying the Foundation

```
adversarial—aspect of collaboration is making high-impact decisions that influence
the project’s direction. When Karl began his first experience coauthoring a book, he
and his coauthor spent a lot of time planning how they would work together, includ-
ing how they would resolve conflicts regarding how to handle a particular topic.
Those involved with every multiperson activity should have this same discussion
before they confront their first conflict.
Decisions related to requirements should use the business requirements as their
North Star. Rely on your business objectives to make choices that keep the work
focused on delivering the desired value. Some teams write their business objectives,
vision statement, and scope descriptions on a large poster. They bring this poster
to discussions about requirements (or present a refresher slide show to open vir-
tual meetings) to help them choose the appropriate course of action. These actions
remind everyone of the goals they’re working together to achieve.
The objective of all decision-making is to expeditiously and respectfully reach
closure on issues based on accurate information, thoughtful analysis, and honest
negotiation. The process for making a decision is called a decision rule. There are
numerous possible decision rules, including these (Gottesdiener 2002, Pichler 2016):
```
```
Unanimous Vote. The participants vote on the options, and all must vote the
same way to resolve the issue. It can be time-consuming, and sometimes impos-
sible, to lead a group of people with diverse interests to all agree on a given out-
come. If achieved, unanimity provides the strongest group commitment to the
decision. An outside facilitator can help a group achieve either unanimous agree-
ment or consensus when buy-in across the board is essential.
Consensus. All participants agree that they can live with the group’s decision,
although they may vary in their commitment to it and their comfort level with it.
Consensus is not as strong an agreement as unanimous voting. Reaching a con-
sensus often requires considerable discussion and compromise. It takes longer
than a simple vote, but the consensus-building process achieves more solid buy-in
to significant decisions.
Plurality Vote. The decision makers vote on the options, and the one that receives
the most votes is selected as the decision. Plurality (sometimes called major-
ity) voting is most appropriate for low-impact decisions that have several clear
options.
Decision Leader Decides. A single individual can make decisions more quickly
than a group can. Depending on the decision leader’s knowledge and expertise
regarding the issue, the leader can either solicit input from others or reach a con-
clusion on their own. Soliciting others’ input is more collaborative and promotes
```

### Practice # 5 : Identify Empowered Decision Makers 43

```
stronger commitment to the outcome by those whom the decision affects. If peo-
ple feel that their voice was not heard before the decision leader set the direction,
they’ll be less satisfied with the result.
Delegation. The leader appoints someone else who has the appropriate knowl-
edge to decide. The leader should not use delegation to avoid responsibility for
whatever course of action the delegate chooses. Delegating the decision to some-
one else demonstrates trust in the delegate’s experience and judgment. However,
if the decision leader overrides the delegate’s decision, that undermines the trust
and effectively reverts to the Decision Leader Decides rule.
```
No single decision rule applies universally to situations; there’s no “correct” rule.
Nonetheless, every group that must make decisions about requirements issues should
agree on its process—and then follow it.

## What Happens Following the Decision?

The most important outputs from any meeting or discussion are action items to pur-
sue, issues to address, and decisions that were made. Decisions have a way of resur-
facing when someone down the road isn’t aware of the outcome, doesn’t agree with
it, or doesn’t understand why it was made. The team should record its significant
decisions along with the rationale behind each one. This record makes the decision
outcome available to others who weren’t involved in the discussion. The team should
discuss how to justify the decision to others who might challenge it.
The results of nonlocal decisions also need to be communicated to those whom
the decision affects. Without clear and timely communication, team members
might implement requirements that were canceled or deferred, misunderstand pri-
orities, or otherwise work at cross purposes. When project participants understand
the reasoning behind significant decisions, they can better collaborate toward com-
mon ends.

## Related Practices

```
Practice #3. Define the solution’s boundaries.
Practice #4. Identify and characterize stakeholders.
Practice #9. Elicit and evaluate quality attributes.
Practice #13. Prioritize the requirements.
Practice #20. Manage changes to requirements effectively.
```

### 44 Chapter 2 Laying the Foundation

## Next Steps

```
1.Review the common requirements decisions listed at the beginning of this
section and identify those that apply to your situation. Does your project
encounter any other requirements-related decisions that are not on that list?
2.Is it clear who the decision makers would be for each category from the
previous step? If not, identify them now.
3.If you have groups who are involved in the major requirements decisions from
the previous steps, determine whether they have selected appropriate decision
rules. If they have, find out if they apply them regularly and whether those
rules work well. If they don’t have decision rules in mind, help them make that
selection.
4.Establish a convention regarding how your project or program will record and
communicate its key decisions to those stakeholders who need to be informed
about them.
```

