USE-CASE 3.0 The Guide to Succeeding to Use Cases



\# USE-CASE 3.



The Guide to Succeeding with Use Cases



\*\*Ivar Jacobson\*\*



\*\*Ian Spence\*\*



\*\*Keith de Mendonca\*\*



December 2024



V1.





\## USE-CASE 3 .0 The Guide to Succeeding with Use Cases





&#x20;  - Page

\- About this Guide

\- Preface

\- What is Use-Case 3.0?

\- The Use-Case Foundation

\- Underlying Principles

\- Core Concepts

\- A simple example

\- Use-Case 3.0 extends the Use-Case Foundation

\- One additional Principle

\- Use-Case 3.0 adds concepts to the Use-Case Foundation

\- Exploring the Principles

\- Principle 1: Universally Applicable

\- Principle 2: Start with the big picture

\- Principle 3: Focus on value

\- Principle 4: Involve your stakeholders

\- Principle 5: Tell the whole story

\- Principle 6: Trigger conversations

\- Principle 7: Prioritize readability

\- Principle 8: Just enough, just in time

\- Principle 9: Implement in stages

\- Principle 10: Build the system in slices

\- Use Case 3.0 Practice Family

\- Building blocks for use-case practitioners

\- 1 - Use-Case 3.0 Foundation practice

\- 2 - Use-Case Storytelling practice

\- 3 - Use-Case Light Modeling practice

\- 4 - Use-Case Authoring practice

\- 5 - Use-Case Structured Modeling practice

\- An example of practice composition

\- Another example of Use-Case practice composition

\- Anatomy of Use-Case 3.0 Practices

\- Use Case 3.0 uses the Essence language

\- Alphas

\- Work Products

\- Activities

\- Using Use-Case 3.0

&#x20;  - Page USE-CASE 3 .0 The Guide to Succeeding with Use Cases

\- Use-Case 3.0: Applicable for all types of system

\- Non-functional requirements

\- Use-Case 3.0: Applicable for all development lifecycles

\- Use-Case 3.0: Scaling to meet your needs – scaling in, scaling out and scaling up

\- Conclusion

\- Appendix 1: Relationship between Use-Case 3.0 practices

\- Appendix 2: Work Products

\- Glossary of Terms

\- Acknowledgements





USE-CASE 3 .0 The Guide to Succeeding with Use Cases

Page 4



\## About this Guide



```

This guide describes how to apply use cases to capture system requirements in an agile and scalable fashion.

It builds on feedback and lessons learned since the initial publication of the Use-Case 2.0 e-book in 2011. Our

goal is to provide you with an integrated family of use case practices which help you get the most out of your

use cases. The practices are applicable for small co-located agile teams, and are also applicable to large,

distributed teams, outsourcing, and complex multi-system developments.

```

```

Use cases can be used to capture the “intended” requirements of a system not yet built, and they may also

be used to describe the “implemented” requirements of an existing system. Throughout this guide we will

use the term requirements to refer both to intended requirements as well as implemented requirements.

```

```

Use cases can be applied in many ways to systems of all types and sizes: businesses, IT systems, physical

systems or any combinations. Different teams need to select their way of working. To meet that demand Use-

Case 3.0 provides a family of practices from which teams can select several such elements and compose them

to a proper fit for the team.

```

```

You can treat these new use case 3.0 practices like a set of building blocks. Select, mix and match the use

case practices described in this guide to customize your use cases in a way that matches the simplicity, or

complexity of your work. You can use each block on its own, or you can use them together - to build up an

enhanced use case practice when you need to apply more rigor and structure to your use case work. Add

more building blocks (i.e. use-case practices) later if you need to add more detail and structure to guide your

work as it progresses.

```

```

For example, one team may only want to describe use cases as simple storytelling, another team prefers to

describe its use cases visually, a third team may want to both have storytelling and visualization, a fourth

team may want to apply deeper authoring combined with visualization, etc. To provide the ability to create

high flexibility for teams to select what they need and to avoid a lot of repetition, the individual practices in

Use-Case 3.0 are reusable building blocks to use when composing the team’s concrete practice.

```

```

This guide also outlines how to create user stories from use cases - it connects the power of use cases to the

complementary benefits of user stories. Use-Case 3.0 is 100% compatible with teams that are already using

user stories.

```

```

We also provide an introduction to the idea of use cases and their application. It is deliberately kept

lightweight. This is not a comprehensive guide to all aspects of use cases, or a tutorial on use-case modeling.

For example, it is not intended to teach you how to model; for this we refer you to our previously published

books on the subject.

```



USE-CASE 3 .0 The Guide to Succeeding with Use Cases

Page 5



\## Preface



```

The guide is structured into the following main chapters:

```

1\. What is Use-Case 3 .0?

2\. The Use-Case Foundation – An overview of the 2024 agreement published by Ivar Jacobson and

&#x20;   Alistair Cockburn.

3\. Exploring the Principles - An introduction to use cases based around the principles that act as

&#x20;   the foundation for the practice family.

4\. Use-Case 3 .0 Practice Family – A summary of when and how to apply the practices that make up Use-

&#x20;   Case 3.0.

5\. Anatomy of Use-Case 3.0 practices – a description of the key concepts, activities, work products,

&#x20;   and the rules that bind them together.



```

If you are new to use cases then you might want to read the “What is Use-Case 3 .0?”, the “Exploring the

Principles”, and the “Use-Case 3 .0 Practice Family” chapters to understand the basic concepts. You can then

dip into the “Anatomy of Use-Case 3 .0 Practices” as and when you start to apply the practice.

```

```

If you are familiar with the basics of use cases, then you might prefer to dive straight into the “Use-Case 3.

Practice Family” and “Anatomy of Use-Case 3.0 Practices” chapters once you’ve read the “What is Use-Case

3 .0?” chapter. This will help you compare Use-Case 3 .0 with your own experiences and understand what has

changed.

```

```

If you have previously read or applied Use-Case 2.0 then you will recognize the structure of the new practices.

Read the “Exploring the Principles” chapter to familiarize yourself with the update, and then follow the

advice above for people already familiar with use cases.

```

```

Throughout this document you will discover how use cases can be used to generate user stories and be used

as an integral part of any agile development practice.

```



USE-CASE 3 .0 The Guide to Succeeding with Use Cases

Page 6



\## What is Use-Case 3.0?



```

Use-Case 3 .0 is a scalable, agile practice family that uses use cases to capture a set of requirements and

drive the incremental development of a system to fulfill them.

```

```

Use-Case 3.0 drives the development of a system by first helping you understand how the system will be

used and then helping you evolve an appropriate system to support the users. It can be used alongside your chosen

management and technical practices to support the successful development of software and other forms of

system. As you will see Use-Case 3 .0 is:

```

```

● Lightweight

● Scalable

● Adaptable

● Easy to use

● Presented as a family of practices to aid adoption and focus on addressing your immediate

concerns

Use cases make it clear what a system is going to do and, by intentional omission, what it is not going to do.

They enable the effective envisioning, scope management and incremental development of systems of any

type and any size. They have been used to drive the development of software systems since their initial

introduction by Ivar Jacobson at OOPSLA in 1987. Over the years they have become the foundation for many

different methods and an integral part of the Unified Modeling Language. They are used in many different contexts

and environments, and by many different types of team. For example, use cases can be beneficial for both

small agile development teams producing user-intensive applications and large projects producing complex

systems of interconnected systems, such as enterprise systems, product lines, and systems in the cloud.

```

```

The use-case approach has a much broader scope than just requirements capture which we currently cover

in this book. Use cases can and should be used to drive the development, which means that Use-Case 3 .0 in

later versions is intended to also supports the architecture, design, planning, estimation, tracking and testing of

systems. It does not prescribe how you should plan or manage your development work, or how you should design,

develop, or test your system. It does however provide a structure for how such practices will be added later on.

```

```

Use-Case 3 .0 exists as a proven and well-defined set of practices. Although the term Use-Case 3 .0 suggests a

new version of use cases, it does not refer to an update of the Unified Modeling Language, but rather to

cumulative changes in the way software developers and business analysts apply use cases. A use case is still a use

case but the ways that we present, address, and manage them have all evolved to be more effective. The

changes are not theoretical but are pragmatic changes based on almost 4 0 years of experience from all over

the world and all areas of software development.

```

```

To get to the heart of what a system must do, focus on who or what will use it, and then look at

what the system must do for them to help them achieve their goals.

```

```

A use case is all the ways of using a system to achieve a goal of a particular user.

```



USE-CASE 3 .0 The Guide to Succeeding with Use Cases

Page 7



\## The Use-Case Foundation



```

The success of use cases has been so widespread that the term use case has even entered common everyday

use. For example, the Meriam Webster on-line dictionary contains the following definition:

```

```

use case:

a use to which something (such as a proposed product or service) can be put

```

```

There are various use cases for the cloud: website hosting, disaster recovery, ... etc.

● Users seem to want single-purpose mobile apps that nail a specific use case quickly.—Josh Constine

● The pandemic has pushed the adoption of technology for various use-cases .— businesswire.com

```

```

In fact, it’s rare for a new product to be launched these days without some reference to its use cases:

```

```

FIGURE 1 : THE TERM “USE CASE” IS NOW USED IN COMMON EVERYDAY USE

```

```

The success of this technique has resulted in a great number of books and articles being written about use

cases. Inevitably over the years, a variety of diverging opinions have been published about what a use case

is, and how a use case should be applied.

```

```

To remedy this situation, Ivar Jacobson and Alistair Cockburn published in 2024 a set of principles and

concepts that underlie all successful applications of use cases. This was called The Use-Case Foundation

document.

```



USE-CASE 3 .0 The Guide to Succeeding with Use Cases

Page 8



\## Underlying Principles



```

Nine foundational principles were agreed by Ivar Jacobson and Alistair Cockburn, published in the 2024 Use-

Case Foundation:

```

1\. Use cases apply to systems of all types and sizes: businesses, IT systems, physical systems or any

&#x20;   combinations thereof.

2\. Use cases help you understand the big picture: the system’s purpose and how it will be used.

3\. Use cases focus on value: the users’ goals and how best to achieve them.

4\. Stakeholder involvement is essential: bring all the involved parties together to establish the intent

&#x20;   and scope of the system.

5\. A use case tells the whole story, as a story, from the initial event to the realization of the value

&#x20;   it provides or the eventual failure if it can’t be met. It includes how to handle any problems and

&#x20;   alternatives that may occur on the way.

6\. Use cases trigger conversations: while discussing the possible scenarios, you and your co-writers

&#x20;   will think of missing steps and missing extensions. These conversations help you find situations

&#x20;   that often get overlooked.

7\. Prioritize readability: the goal is to communicate the big picture to everyone involved, generating

&#x20;   comments, spotting any gaps, and getting their buy-in.

8\. The amount of detail and the format used will vary to match your circumstances: You can start

&#x20;   with a sketch of the sequence of events and add detail as needed.

9\. A use case can be implemented in stages: develop and put into place some key scenarios of a use

&#x20;   case early to capture value and feedback, add less used or less critical scenarios over time

&#x20;   strategically.



\## Core Concepts



```

The Use-Case Foundation also defines a set of concepts:

```

1\. A system of interest.

2\. An actor with a goal.

3\. A set of scenarios (there will be several)

4\. A use case to collect those scenarios.

5\. A primary actor which initiates a use case.

6\. The system may call upon a supporting actor to support the operation of a use case.



```

FIGURE 2 : A USE CASE

```

```

A Use Case – A use case is all the ways of using a system to achieve a goal of a particular user:

```

```

● This includes all the successful, challenged and failure paths.

● It may be described textually or visually.

● It is independent of implementation, technology, and platform.

```



USE-CASE 3 .0 The Guide to Succeeding with Use Cases

Page 9



```

The System of Interest – The system used to achieve the goal.

```

```

An Actor – An actor identifies a role played when interacting with the system. “Actor” is intended to cover

anything with behavior. It can be a person, an organization, a piece of software, or any combination.

```

```

A use case might involve many actors: the actor that initiates a use case is known as the “primary actor” and

the actors called upon by the system are known as “supporting actors”.

```

```

The Goal – The reason that the user will use the system and the value that they will receive when successfully

using the system.

```

```

Scenario - a complete sequence of steps through the whole use case. This is described as a simple sequence

of steps, each of which involves the system and / or one of the actors doing something.

```

```

The Basic Scenario – The normal, happy path to value often referred to as the ‘main success scenario’,

‘basic flow’ or the ‘happy path’.

```

```

Extensions – A list of all the special cases, alternative paths, optional steps, and errors that need to be

handled. Extensions are also referred to as “alternate flows”.

```

```

FIGURE 3 : AN OVERVIEW OF THE USE-CASE FOUNDATION

```

```

These are the foundational concepts and principles that underlie all successful applications of Use Cases.

```

\## A simple example



```

Let’s assume you are a musician who would like to find a new guitar to purchase from a music store over the

internet. With respect to an online music store, what role would you be playing and what would be your goal

with respect to the system?

```

```

When using use cases, we don’t want to have a separate actor for every type of shopper (guitarist, bassist,

singer, parent, school, manager etc.) and a different use case for every different product we sell (guitars,

oboes, microphones, effect pedals etc.) as the way they interact with the system to browse and shop for

products will be the same. We would probably end up with something like the use-case shown in FIGURE 4.

```



USE-CASE 3 .0 The Guide to Succeeding with Use Cases

Page 10



```

FIGURE 4 : THE BROWSE AND SHOP USE CASE

```

```

Although this use case captures the most valuable thing that our on-line music shop can do it probably isn’t

sufficient to make a usable system. Some other use cases may be required such as those shown in bold in

FIGURE 5 :

```

```

FIGURE 5 : EXPANDING OUR SET OF USE CASES

```

```

If you look closely, you might find issues and problems with this diagram such as missing actors, missing use

cases and confusing names. This is deliberate. This is exactly the sort of conversation that we want the Use-

Case Model and any supporting overview diagrams to start.

```



USE-CASE 3 .0 The Guide to Succeeding with Use Cases

Page 11



```

FIGURE 6 : BASIC SCENARIO AND EXTENSIONS

```

```

Scenario : A scenario is a specific instance of a use case - describing specific inputs from the user in response

to specific events, and with specific values produced by the system. These inputs, events and outputs may

all be considered as variables which define the complete execution path through the use case - from when

the use case is triggered by the actor, to when the use case ends.

```

```

Consider the following 3 scenarios which describe the use case for an ATM. In this example, there are typically

two variables: the PIN code and the limit amount for withdrawal.

o Scenario 1 : The user enters correct credentials and withdraws cash.

o Scenario 2 : The user enters incorrect credentials three times and the account is locked.

o Scenario 3 : The user forgets the password and resets it before logging in and withdraws cash.

```

```

We will refer to these example scenarios below.

```

```

The Basic Scenario – The normal path through the use case to reach the goal - often referred to as the ‘happy

path.’ This is described as a simple sequence of steps each of which involves the system and / or one of the

actors doing something. This sequence is traditionally called the “basic flow " or “main success scenario”.

The basic scenario always describes a full path through the use case – from when the use case is triggered

by the actor, to the end of the use case when that actor achieves their goal (see FIGURE 6 ).

```

```

Scenario 1 in the above example is the basic scenario – where the use case ends with the user achieving their

goal. Note that we could view Scenario 1 as one specific instance of a use case – e.g. when the legal PIN code

number 1234 is entered to gain access for one specific user “Ivar”. Or we could view it as a basic scenario

when any legal PIN code is entered to allow an authorized user to gain access. In this ebook we treat both of

these cases as a basic scenario; the first can be used to generate a specific test scenario with test parameters

“Ivar” and “1234”; the second example is useful as a general illustration of the “happy day” behavior of this

use case, which can also be used to identify test cases.

```

```

Extensions – Represent two different types of paths: the first type is an alternative path through the use case

that diverges from the basic scenario to complete one or more alternate steps, and which then returns to

complete the basic scenario in order to reach the use-case goal. The second type of extension represents a

path through the use case which diverges from the basic scenario due to an error condition that needs to be

handled, and which then results with the user failing to reach their goal when the use case ends ( FIGURE 6 ).

```

```

In Scenario 2 the use case ends with the user failing to achieve their goal. Scenario 3 describes an alternate

scenario through the use case where the user still reaches their goal.

```



USE-CASE 3 .0 The Guide to Succeeding with Use Cases

Page 12



```

The key aspect of a use case is its structure: the way it identifies the basic scenario and its extensions – this

acts as a map of how the system will be used. The basic scenario can be described as simply as a bulleted list

of steps, and names for the extensions. Or it can be elaborated to fully describe what should happen at each

step or within each extension. It can be described in text, as above, or in some graphical form. FIGURE 7

presents a simple example of the basic scenario enumerated for the Browse and Shop Use Case, and a list of

the names describing each of the extensions.

```

```

Although there are potentially hundreds of scenarios that could describe different instances of a use case

(e.g. buy one product with cash, or buy several products with a credit card, try to buy a million products with

BitCoins), it would not be practical or sensible to describe them all. Instead, we suggest you focus on

identifying a small number of extensions which cover sufficient success and failure execution paths through

the use case to illustrate clearly its scope and its complexity. Additional extensions can be added to the use

case description as and when they become important to describe.

```

```

FIGURE 7 : AN OUTLINE OF THE BROWSE AND SHOP USE CASE

```

\*\*Scenarios, Extensions and Flows\*\*



```

There are several related concepts used in the literature; many use case authors describe an " alternative

flow ", or an “ extension ”. In this ebook we try to be consistent with using the term extension, but sometimes

we may also synonymously use the terms ‘a flow of events’ or ‘a path through a use case’. Some authors may

put in a distinction between these two terms, but to us the difference is minor, namely a scenario is a

description of a complete execution from start to finish, while ‘a flow of events’, ‘a path through a use case’

or ‘an extension’ all could just mean a part of that scenario which is of interest.

```



USE-CASE 3 .0 The Guide to Succeeding with Use Cases

Page 13



\## Use-Case 3.0 extends the Use-Case Foundation



```

The Use-Case Foundation principles were published in 2024 to remind practitioners to capture “just-enough”

detail, “just-in-time”, and “deliver in stages”; the development of use cases should be done in a way that

suits the circumstances – in some cases in a lightweight and agile way, in other cases in a rigorous way.

```

```

To assist with this agile way of working, Use Case 3.0 has been created specifically to provide a family of

practices – offering use-case practitioners a set of “building block” use-case practices for the first time. Each

use-case practice can be used alone or be combined together to provide the right level of detail required. By

selecting and applying the right use-case practice at the right time, practitioners can now avoid the trap of

“big up-front requirements” or “big up-front design.”

```

```

What is in Use-Case 3.0? Specifically, the Use-Case 3.0 Foundation adds:

● a number of additional concepts – including the concept of use-case slices.

● a tenth principle relating to use-case slicing.

```

```

New concepts are defined by the relevant Use-Case 3.0 practices – thus ensuring that new concepts and new

work products are described with precision for that practice, and also to ensure they are only applied when

the relevant practice is selected for use.

```

```

Let’s now look in more detail at the additional principle and concepts introduced by the Use-Case 3.0.

```

\## One additional Principle



```

The principles of Use-Case 3.0 are identical to the Use Case Foundation principles, but with a tenth principle

added:

```

\*\*10.\*\* \_A system can be developed in slices where each slice is one or more paths through one of the

system’s use cases plus the relevant design, code and tests used to implement and verify them.\_



\## Use-Case 3.0 adds concepts to the Use-Case Foundation



```

Use-Case 3.0 is built on top of the Use Case Foundation. As mentioned before, it adds a number of additional

concepts that allow a use case to be described with more precision. In this section we will look at some

additional core concepts that underpin Use-Case 3.0:

● A Use-Case Model – A model that captures and visualizes all the useful ways to use a system.

● Use-Case Slice - A slice of a use case that provides clear value to the development stakeholders.

Use-Case slices are used to stage the development of the use case.

● A Work Item – a small, actionable piece of work that can be given to an individual or team to

complete. Most use-case slices will require multiple work items to be completed to complete

their development and testing. Common forms of work item used to implement a use-case slice

include user stories, Features and Tasks.

```



USE-CASE 3 .0 The Guide to Succeeding with Use Cases

Page 14



```

FIGURE 8 : THE UNDERLYING PRINCIPLES AND CORE CONCEPTS FOR USE-CASE 3.0 FOUNDATION

```

```

FIGURE 8 displays how Use-Case 3.0 builds on top of the Use-Case Foundation – but adds important additional

concepts. In Use Case 3.0 we use the same terminology as version 1.1 of the Use-Case Foundation: “basic

flow” is renamed to “basic scenario”, and “alternate flow” is renamed to “extension.”

```

```

We will now explore some important Use-Case 3.0 concepts in more detail below.

```

\*\*Use-Case Model\*\*



```

A use-case model is a model of all the useful ways to use a system. It allows you to very quickly scope the

system – what is included and what is not – and give the team a comprehensive picture of what the system

will do. It lets you do this without getting bogged down in the details of the requirements or the internals of

the system. With a little experience it is very easy to produce use-case models for even the most complex

systems, creating an easily accessible big picture that makes the scope and goals of the system visible to

everyone involved.

```

```

A use-case model is presented by one or more use-case diagrams. Thus, a use-case diagram is a view into the

use-case model. Different diagrams may present different views and consequently the same use case symbol

may appear in more than one diagram.

```

```

Use-case models acknowledge the fact that systems support many different goals from many different

stakeholders. In a use-case model the stakeholders that use the system and contribute to the completion of

the goals are modeled as actors, and the ways that the system will be used to achieve these goals are modeled

as use cases. In this way the use-case model provides the context for the system’s requirements to be

discovered, shared, and understood. It also provides an easily accessible big picture of all the things the

system will do.

```

```

FIGURE 9 (below) shows the use-case diagram for a simple telephone system. The actors are shown as stick-

figures and the use cases as ellipses. The arrowheads indicate the initiator of the interaction (an actor or the

system) allowing you to clearly see who starts the use case.

```

```

From this picture you can see all the ways the system can be used, who starts the interaction, and any other

parties involved. For example, a Calling Subscriber can place a local call or a long-distance call to any of the

system’s Callable Subscribers. You can also see that the users don’t have to be people but can also be other

systems, and in some cases both (for example the role of the Callable Subscriber might be played by an

answering machine and not a person).

```



USE-CASE 3 .0 The Guide to Succeeding with Use Cases

Page 15



```

FIGURE 9 : USE-CASE DIAGRAM FOR A SIMPLE TELEPHONE SYSTEM

```

```

Note: Use Cases vs Features and Functions - it is important to understand that the use cases describe all

the ways that a user can use the system; they are not descriptions of system features. Since a use case is

bound to a system entity, it is not subject to traditional functional decomposition. If a use case is split into

subordinate use cases, each subordinate use case is a use case of that subordinate system (e.g. a subsystem)

```

\- with its own goal. A use case is not a feature.



\*\*Use-Case Slice\*\*



```

We define a Use-Case Slice as: A slice of a use case that provides clear value to the development

stakeholders. It includes a requirements slice specifying the interaction with its actor(s) and the actions

taken by the use case, and a test slice verifying the requirements.

```

```

Use-Case slices are used to stage the development of the use case. It is the development team that slice the

use case, ensure that our slices are actionable, and prioritize the slices for development. Each use-case slice

acts as a placeholder for all the work required to deliver the value to the development implicit in the slice.

The use-case slice evolves to include the corresponding slices through design, implementation, and tests.

```

```

Use-case slices give value to the development team which usually includes a user representative. Note that

the value of the slice has no direct relationship to the goal of the actor interacting with the use case.

```

```

Use-case slices are a valuable tool for building smaller increments on the way to a complete release. They

allow you to target independently implementable and testable slices - ensuring that each increment builds

on the one before. If the team wishes to deliver incremental releases to the user slice–by-slice, then the user

representative for that team must ensure each slice not only satisfies the development needs of the team,

but they also allow the user to evaluate quickly some aspect of the new system behavior, or to use the

updated system.

```

```

The concept of a use-case slice is as integral to Use-Case 3.0 as the use case itself. It is the slices that enable

```



USE-CASE 3 .0 The Guide to Succeeding with Use Cases

Page 16



```

use cases to be broken down and delivered in stages. Imagine that you are part of a small team producing

working software every two weeks. A whole use case is in many cases too much to be completed by the

development team in one two-week period. A use-case slice though is another matter because it can be sliced

as thinly as the team requires. Use-case slices also allow the team to focus on providing a valuable, usable

system which the development stakeholder (or user) can assess as soon as possible, shedding all unnecessary

requirements on the way.

```

```

Let’s look at an example of use-case slicing. The Browse and Shop use case described in FIGURE 7 describes

the basic scenario and twelve extensions. You will see that all of these extensions are too much work to

implement in one go, and potentially more than you would ever want to implement. Even the basic scenario

may be too much to address in your first pass. This is where the idea of use-case slices comes into play.

```

```

FIGURE 1 0 shows an initial slicing up of the Browse and Shop use case. Here, six slices have been identified.

These are considered to be sufficient to provide a robust, usable user experience.

```

```

FIGURE 10 : SLICING UP BROWSE AND SHOP

```

```

Things to note here are that:

```

1\. Not all extensions have been included in the slicing. There is no need to slice up the entire use

&#x20;   case. Extensions considered to be out of scope or that are not important at the moment can just

&#x20;   be left unsliced as part of the use case.

2\. Multiple slices have been identified from the basic scenario. In this case we have decided to

&#x20;   separate buying a single product from buying multiple products. This is to enable the early

&#x20;   implementation and testing of an end-to-end thread through the use case without having to

&#x20;   wrestle with the issues of handling multiple product selection and deliveries.

In the example above, we could identify, implement and test the first two slices first of all, and then find

and enumerate all of the extensions later on. As later slices are identified, the scope of each slice may evolve

\- as more is learnt about the user’s needs and about errors that need to be handled.



```

For example, when working on Slice 4 (Handle Customer Data Issues) in the above example, we may

```



USE-CASE 3 .0 The Guide to Succeeding with Use Cases

Page 17



```

discover that our original extensions become a larger set of discrete extensions, or that there are other

relevant Customer Data Issues that should also be handled. These concerns will often be ignored when

addressing a single extension in isolation. But, if we work slice by slice, we can simply add the additional

extensions we have identified to our current slice, or we can create a new slice that represents the newly

identified extensions - to be prepared and completed later.

```

\*\*Work Items\*\*



```

The two most common types of work item we see in use now are user stories (for agile teams) and Tasks (for

waterfall project teams). Regardless of the types of work item to be generated, the basic principle is the

same. The important thing to note here is that Use-Case 3.0 will support, focus and complement whatever

planning, work management and development approaches your teams have selected.

One or more work items will be created by the team to plan and deliver each use-case slice. A team can treat

each use-case slice as one work item or, as described above, the team could create one or more user stories

or project tasks to represent work to build that slice.

```



USE-CASE 3 .0 The Guide to Succeeding with Use Cases

Page 18



\## Exploring the Principles



```

In this section we now look at the underlying principles for Use-Case 3.0 in more detail. We have the nine

principles from the Use-Case Foundation, plus an added tenth principle for Use Case 3.0.

```

\## Principle 1: Universally Applicable



```

“Use Cases apply to systems of all types and sizes: businesses, IT systems, physical systems, or any

combinations thereof.”

```

```

Although traditionally associated with capturing requirements for software systems use cases can be used for

many other purposes and for many other types of system. For example:

```

```

● Use cases have been used to describe the behavior of cyber-physical telephone switching systems.

● Business use cases have been used for many years to help understand what a business does and

how it does it.

Use cases can be used to understand any kind of system including:

```

```

● Organizations

● Businesses

● IT Systems

● Physical Systems

● Infrastructure

```

```

Long-running activities such as supervising a system (e.g. monitoring, error-checking, etc.) can also be

represented by a use case. These use cases may be active for the lifetime of that system.

```

```

This universal applicability is incredibly powerful as it:

```

1\. Allows us to provide a consistent viewpoint on all our systems regardless of the type of system it

&#x20;   is. This makes all our work more accessible to our stakeholders.

2\. We can start to understand the usage and context of our proposed solution before we decide what

&#x20;   type of system we should build.



\## Principle 2: Start with the big picture



```

“Use cases help you understand the big picture: the system’s purpose and how it will be used.”

```

```

Whether the system you are developing is large or small, whether it is a software system, a hardware system,

or a new business, it is essential that you understand the big picture.

```

```

In our “Browse and Shop” example above in FIGURE 4 we started with a simple user goal and a use case exploring

all the ways the system could be used to achieve that goal.

```

```

Each use case presents a big picture of one aspect of the system and is often enough to get started. In the “Browse

and Shop” example if there are no shoppers turning up to browse and shop then our online shop is of no value. We

can then move on to consider other users and their goals ( FIGURE 5 ) until we have created a usable system of clear

value to its users.

```



USE-CASE 3 .0 The Guide to Succeeding with Use Cases

Page 19



```

Without an understanding of the system as a whole you will find it impossible to make the correct decisions

about what to include in the system, what to leave out of it, what it will cost, and what benefit it will provide.

This doesn’t mean capturing all the requirements up front. You just need to create something that sums up

the desired system and lets you understand scope and progress at a system level.

```

\## Principle 3: Focus on value



```

“Use cases focus on value: the users’ goals and how best to achieve them.”

```

```

When trying to understand how a system will be used it is always important to focus on the value it will

provide to its users and other stakeholders. Although it is tempting to create long lists of the functions or

features a system will offer, this is not a useful activity because value is only generated if the system is

actually used. Focus instead on when and how the system will be used by its users.

```

```

Use cases provide this focus by concentrating on how the system will be used to achieve a specific goal for a

particular user. They encompass many ways of using the system; those that successfully achieve the goals,

and those that handle any problems that may occur. To make the value easy to quantify, identify and deliver,

you need to structure the use-case narrative. To keep things simple start with the simplest possible way to

achieve the goal. Then capture any alternative ways of achieving the goal and how to handle any problems

that might occur whilst trying to achieve the goal. This will make the relationships between the ways of using

the system clear. It will enable the most valuable ways to be identified and progressed up front and allow the

less valuable ones to be added later without breaking or changing what has gone before.

```

```

In some cases, there will be little or no value in implementing anything beyond the simplest way to achieve

the goal. In other cases, providing more options and specialist ways of achieving the goal will provide the key

differentiators that make your system more valuable than your competitors.

```

```

FIGURE 11 shows a use-case narrative structured in this way. The simplest way of achieving the goal is

described by the basic scenario. The other ways are presented as names of the extensions. In this way you

create a set of scenarios that structure and describe the work products (e.g. user stories) and help us to find

the test cases that complete their definition.

```

```

FIGURE 11 : THE STRUCTURE OF A USE-CASE NARRATIVE

```

```

This Figure 11 : shows the narrative structure for the Withdraw Cash use case for a cash machine. The basic

scenario is shown as a set of simple steps that capture the interaction between the users and the system. The

extensions identify any other ways of using the system to achieve the goal such as asking for a non-standard

```



USE-CASE 3 .0 The Guide to Succeeding with Use Cases

Page 20



```

amount, any optional facilities that may be offered to the user such as dispensing a receipt, and any problems

that could occur on the way to achieving the goal such as the card getting stuck. For example, E2 represents

the “non-standard amount” extension in which the basic scenario would run until step 4, where a non-standard

amount would be requested by the user, and then the basic scenario would continue to run from step 5 to

the end of the use case.

```

```

You don’t need to capture all the extensions at the same time. Whilst recording the basic scenario it is natural

to think about other ways of achieving the goal, and what could go wrong at each step. You capture these as

extensions but concentrate on the basic scenario first. You can then return to complete the extensions later

as and when they are needed by the development team.

```

```

This kind of bulleted outline may be enough to capture the work products and drive the development, or it

may need to be elaborated as the team explores the detail of what the system needs to do. The most

important thing is the additive structure of the use-case narrative. The basic scenario is needed if the use

case is ever to be successfully completed; this must be implemented first. The extensions may (or may not

be) be optional; they can be added to the basic scenario and when they are needed. This allows you to really

focus on the value to be obtained from the system. You no longer need to deliver the whole use case but can

focus on those parts of the use case that offer the most value. It also means that you don’t need a complete

use-case model or even a complete use case before you start to work on the development of the system. If

you have identified the most important use case and understood its basic scenario, then you already have

something of value you could add to your system.

```

```

This structure makes the work products easy to capture and validate for completeness, whilst making it easy

to filter out those potential ways of using a system that offer little or no real value to the users. This constant

focus on value will enable you to ensure that every release of your system is as small as possible, whilst

offering real value to the users of the system and the stakeholders that are funding the development.

```

\## Principle 4: Involve your stakeholders



```

“Stakeholder involvement is essential: bring all the involved parties together to establish the intent and

scope of the system.”

```

```

Imagine the concern it must provoke in those organizations where the leaders talk about one set of use cases

when publicizing the new system and the developers talk about a different set of use cases, or have no idea

what the intended use cases are, when they are building it.

```

```

It would be much better if everyone was on the same page – and ideally that page is a use case.

```

```

So, involve your stakeholders in conceiving both the use-case model and the individual use cases, and keep

them involved in their evolution and implementation.

```

```

Use cases really are an excellent way to get everyone on the same page.

```

\## Principle 5: Tell the whole story



```

“A use case tells the whole story, as a story, from the initial event to the realization of the value it provides

or the eventual failure if it can’t be met. It includes how to handle any problems and alternatives that may

occur on the way.”

```

```

Storytelling is how cultures survive and progress; it is a simple and effective way to pass knowledge from one

person to another. We can use storytelling to communicate what a system should do, and to get everybody

working on the system to focus on the same goals.

```



USE-CASE 3 .0 The Guide to Succeeding with Use Cases

Page 21



```

The use cases capture the goals of the system. To understand a use case, we tell stories. The stories cover

how to successfully achieve the goal, and how to handle any problems that may occur on the way. Use cases

provide a way to identify and capture all the different but related stories in a simple but comprehensive way.

This enables the system’s use cases to be easily captured, shared and understood.

```

```

As a use case is focused on the achievement of a particular goal, it provides a focus for the storytelling.

Instead of describing the system in one go we can approach it use case by use case. The results of the story-

telling are captured and presented as part of the use-case narrative that accompanies each use case.

```

```

When storytelling is used as a technique to communicate requirements it is essential to make sure that the stories

are captured in a way that makes them actionable and testable. A set of test cases accompany each use-case

narrative to complete the use case’s description. Test cases are the most important part of a use case’s

description, even more important even than the use-case narrative. This is because they make the stories real,

and their use can unambiguously demonstrate that the system is doing what it is supposed to do. Test cases

define what it means to successfully implement the use case. Test cases will also verify the system continues to do

what it is supposed to do after implementation is complete, and when other system changes are made afterwards.

```

\## Principle 6: Trigger conversations



```

“Use cases trigger conversations: while discussing the possible scenarios, you and your co-writers will think

of missing steps and missing alternatives. These conversations help you find situations that often get

overlooked.”

```

```

Use cases and use-case models are intended to trigger conversations – one of the most powerful things about

use cases is that they put the conversations into context.

```

```

We’ve already discussed how a simple outline of a use case will trigger conversations about the steps in the

use case and the coverage of the extensions (also known as ‘alternate flows’).

```

```

Now you may think this sounds quite trivial and that these things are boring and easy to capture but bear this

in mind:

```

```

We were once running a use-case workshop for one of the world’s biggest banks who were in the

process of building a new platform for electronic funds transfer to help them seamlessly integrate all

the various banks they had been acquiring around the world.

```

```

As is not unusual at this kind of event the techies sat together on one table and all the business people

sat together on another. One of the introductory exercises we did was to outline the basic scenario of

the Transfer Funds Use Case. A simple exercise you’d have thought but when it came time to share

their outlines the techies stood up and walked through the steps of their basic scenario. Much to their,

and our, amazement the business people just started laughing. What could be so funny? They had just

presented the steps involved in the existing automated process for the main bank. Well, it turned out

that they were in the wrong order. “Do you know how many millions that has cost the bank?” asked

the main business sponsor.

```

```

Well clearly, they didn’t, as it was exactly what they had intended to implement in the new system.

```

```

Luckily the outline had triggered a new conversation and bought everyone involved much closer

together in their understanding of the intent of the new system.

```

```

Just as a use case can start a conversation about the ways that a user goal should be addressed, the use-case

model starts conversations about the scope of the system as a whole. For example, is there anything missing,

```



USE-CASE 3 .0 The Guide to Succeeding with Use Cases

Page 22



```

are we doing too much, is everything identified really needed, what do we need to have in place to go live,

what would be a good MVP (minimal viable product), are we talking to the right actors and so on. They can

also be used to trigger conversations with customers and to support the business case.

```

\## Principle 7: Prioritize readability



```

“Prioritize readability: the goal is to communicate the big picture to everyone involved, generating

comments, spotting any gaps, and getting their buy-in.”

```

```

It’s worth taking a few moments to think about how we typically present the requirements for our

development work.

```

```

On one hand we have the agile teams who like to capture everything on sticky notes. This often results on a

huge number of small requests being captured and collected into a prioritized list. Individually these are small

and accessible but can make it very difficult to get an overview of what is being built, what has been achieved

so far and what there is left to do.

```

```

On the other hand, we have more waterfall projects where traditionally all the detailed requirements are

captured up front before development starts. This often results in the production of a huge impenetrable

document that takes hours to read and once again obscures the big picture.

```

```

Use cases done well hit the sweet spot in between these two extremes but you need to prioritize readability

in both the use-case model and the use cases. Even when, for legal or other reasons, you need to capture a

lot of detail in your use cases you should make sure that you keep them readable and start with a simple one-

page overview of the scenarios.

```

\## Principle 8: Just enough, just in time



```

“The amount of detail and the format used will vary to match your circumstances: You can start with a

sketch of the sequence of events and add detail as needed.”

```

```

Unfortunately, there is no ‘one size fits all’ solution to the challenges of system development; different teams

and different situations require different styles and different levels of detail. Regardless of which practices

and techniques you select you need to make sure that they are adaptable enough to meet the ongoing needs

of the team.

```

```

This applies to the practices you select to share your intent, capture your requirements and drive the

development as much as any others. For example, lightweight requirements are incredibly effective when

there is close collaboration with the users, and the development team can get personal explanations of the

requirements and timely answers to any questions that arise. If this kind of collaboration is not possible,

because the users are not available, then the requirements will require more detail and will inevitably become

more heavyweight. There are many other circumstances where a team might need to have more detailed

requirements as an input to development. However, what’s important is not listing all the possible

circumstances where a lightweight approach might not be suitable but to acknowledge the fact that practices

need to scale.

```

```

Use-Case 3 .0 is designed with this in mind and is as light as you want it to be. Small, collaborative teams can

have very lightweight use-case narratives that capture the bare essentials of the requirements. These can be

handwritten on simple index cards. Large, distributed teams can have more detailed use-case narratives

presented as documents. It is up to the team to decide whether they need to go beyond the essentials, adding

detail in a natural fashion as they encounter problems that the bare essentials cannot cope with.

```



USE-CASE 3 .0 The Guide to Succeeding with Use Cases

Page 23



```

The structure of use cases also lends itself to adding the detail just-in-time at the last responsible moment.

For example, although we like to identify all the in-scope use cases up front we don’t need to detail their

basic scenario unless it is needed. The same goes for the extensions, the detailing of these can be deferred

until we are going to work on them.

```

\## Principle 9: Implement in stages



```

“A use case can be implemented in stages: develop and put into place some key scenarios of a use case early

to capture value and feedback, add less used or less critical scenarios over time strategically.”

```

```

Most systems evolve through many generations. They are not produced in one go; they are constructed as a

series of releases - each building on the one before. Even the releases themselves are often not produced in

one go but evolve through a series of increments. Each increment provides a demonstrable or usable version

of the system. Each increment builds on the previous increment to add more functionality or improve the

quality of what has come before. This is the way that all systems should be produced.

```

```

The use cases themselves can also be too much to consider delivering all at once. For example, we probably

don’t need all the ways of placing a local call in the very first increment of a telephone system. The most

basic facilities may be enough to get us up and running. The more optional or niche ways of placing a local

call such as reversing the charges or redialing the last number called can be added in later increments. By

slicing up the use cases we can achieve the finer grained control required to maximize the value in each

release.

```

```

FIGURE 1 2 shows the incremental development of a release of a system. The first increment only contains a

single slice: the first slice from use case 1. The second increment includes another slice from use case 1 and

the first slice from use case 2. Further slices are then added to create the third and fourth increments. The

fourth increment is considered complete and useful enough to be released.

```

```

FIGURE 12 : USE CASES, USE-CASE SLICES, INCREMENTS AND RELEASES

```



USE-CASE 3 .0 The Guide to Succeeding with Use Cases

Page 24



```

Use cases are a fabulous tool for release planning. Working at the use-case level allows whole swathes of

related requirements to be deferred until the later releases. by making decisions at the use-case level you

can quickly sketch out the big picture and use this to focus in on the areas of the system to be addressed in

the next release.

```

```

Use-case diagrams, showing which use cases are to be addressed in this release and which are to be left until

a later release, are a great tool for illustrating the team’s goals. They clearly show the theme of each release

and look great pinned up on the walls of your war-room for everybody to see.

```

\## Principle 10: Build the system in slices



```

“A system can be developed in slices where each slice is one or more paths through one of the system’s use

cases plus the relevant design, code and tests used to implement and verify them.”

```

```

This tenth principle has been added to the original nine Use Case Foundation principles. Use Case 3.0 adds

the concept of slicing a use case as a mechanism to break a use case into smaller deliverable and verifiable

components.

```

```

Most systems require a lot of work before they are usable and ready for operational use. They have many

requirements, most of which are dependent on other requirements being implemented before they can be

fulfilled, and value delivered. It is always a mistake to try to build such a system in one go. The system should

be built in slices, each of which has clear value to the development team building the slice (e.g. adding

functionality, improving performance or the system architecture). If the system is being delivered in

increments to be used by the user, then each increment (consisting of one or more slices) should also be

valuable to the user.

```

```

The recipe is quite simple. First, identify the most useful thing that the system must do and focus on that.

Then take that one thing and slice it into thinner slices. Decide on the test cases that represent acceptance

of those slices. Some of the slices will have questions that can’t be answered. Put those aside for the moment.

Choose the most central slice that travels through the entire concept from end to end, or as close to that as

possible. Estimate it as a team (estimates don’t have to be “right”, they’re just estimates), and start building

it.

```

```

This is the approach taken by Use-Case 3 .0, where the use cases are sliced up to provide direction to the

team, and where the system itself evolves slice by slice. Use-Case slices will be defined more comprehensively

in the next section of this document.

```



USE-CASE 3 .0 The Guide to Succeeding with Use Cases

Page 25



\## Use Case 3.0 Practice Family



```

Use-case practitioners have found many ways to apply use cases. Dependent on the domain of the system (for

instance banking, defense, telecom), its criticality (life-threatening, regulated, complexity, etc.) the need

for modeling and details should be different. To facilitate this diversity Use-Case 3.0 provides a set of use

case practices all described using the international standard Essence as a platform.

```

```

In the following sections we will remind ourselves of the principles and concepts defined by Use-Case 3.0, we

will then describe each practice, its usage and what work products it produces. At the end of this section, we

will introduce some of the more common practice combinations you may wish to use.

```

\## Building blocks for use-case practitioners



```

The Use Case 3.0 practices described here should be seen as a set of building blocks. Each practice is useful on its

own and can be applied to suit a specific need, or they can be composed together in different combinations – to

match the complexity of the modeling task at hand. The Use-Case 3.0 family of practices described in this ebook

are:

```

1\. \*\*Use-Case 3.0 Foundation practice\*\* – defines the principles and concepts described in the Use-Case

&#x20;   Foundation, including one extra tenth principle and one concept to describe a Use-Case Slice.

2\. \*\*Use-Case Storytelling practice\*\* – a lightweight way to describe a use case. The practice describes

&#x20;   activities that create a use-case narrative work product and a supporting information work product

&#x20;   - both produced to a light level of detail.

3\. \*\*Use-Case Authoring practice\*\* – a use case described in greater detail and using a more formal

&#x20;   structure to capture the use-case narrative and any supporting information.

4\. \*\*Use-Case Light Modeling practice\*\* – create a use-case model that is described with a basic level

&#x20;   of detail (i.e. naming the system, actors, use cases, and defining the relationship between actors

&#x20;   and use cases)

5\. \*\*Use-Case Structured Modeling practice\*\* – create a detailed use-case model, which may use

&#x20;   advanced use-case concepts such as extend, include and generalization for actors and use cases.



```

The addition of these “building block” practices in Use-Case 3.0 is one significant improvement we have made over

Use-Case 2.0.

```

```

To understand how these building blocks can be used, imagine we are starting a new endeavor. We may first wish

to sketch out a simple use-case model to determine what initial use cases must be satisfied and to agree the “big

picture” of the new solution. We could select the Use-Case Light Modeling practice to do this work. Now we have

named some of the use cases and actors but not necessarily all them.

```

```

We might now select one of the identified use cases and investigate it in greater depth – perhaps selecting the Use-

Case Authoring practice to create a detailed use-case narrative. Moreover, we might decide to only apply the Use-

Case Storytelling practice to the other use cases - to sketch out only the essential details of the use-case narrative,

and to capture pertinent supporting information.

```



USE-CASE 3 .0 The Guide to Succeeding with Use Cases

Page 26



\## 1 - Use-Case 3.0 Foundation practice



```

The foundational concepts and principles underlie all successful applications of Use Case 3.0. The Use-Case

3.0 Foundation extends the Use-Case Foundation to add the key Use-Case 3.0 concepts of the Use-Case Slice

and to elaborate the states of the Use Case Alpha, whilst adding an additional principle ‘build the system in

slices’.

```

```

The Use-Case 3.0 Foundation practice also adds the concept of “Work Item” – an addition which enables Use-

Case 3.0 practices to be composed with other popular practices such as user stories, Scrum, Kanban,

integration with larger agile frameworks such as SAFe, Scrum@Scale, Nexus, or with more traditional task-

based planning approaches (such as waterfall-driven projects).

```

```

FIGURE 13 : PRINCIPLES AND CONCEPTS DEFINED BY THE USE-CASE 3.0 FOUNDATION PRACTICE

```

```

Note that this foundation practice is not a concrete practice - you would not use it on its own. It is described here

just for the sake of completeness. All use-case 3.0 practices are built on top of this foundation practice – they are

all extensions of this practice.

```



USE-CASE 3 .0 The Guide to Succeeding with Use Cases

Page 27



\## 2 - Use-Case Storytelling practice



```

This practice describes a single use case. It produces a simple Use-Case Narrative to capture each use case of

your system. The practice also provides the concept of use-case slicing, which enables an incremental delivery

of a system.

```

```

You can use this practice stand-alone when:

```

```

● You want to understand one or more critical use cases of your system.

● You need to create some valuable short-term goals for your team.

● You would like use cases to provide some structure and context to your user story backlog.

Or in conjunction with a use-case modeling practice (described below):

● to create a simple overview of the value your system provides.

```

```

Note: Use-Case Storytelling does not include any use-case modeling. If this practice is used alone, the

development team suggests a use case to focus on as part of the “Describe and Slice a Use Case” activity.

```

```

This practice adds an additional concept that can be used to capture and document your Use-Cases as part of

the Use-Case Narrative work product: Constraints (e.g. any to capture pre-conditions, post-conditions, etc.).

```

```

Once stakeholders have agreed the scenarios desired, the development team can identify one or more user

stories to implement the basic scenario, identify additional user stories to implement each extension and to

handle exceptions. The development team can then discuss with stakeholders how to group those user stories

together into coherent use-case slices - and so identify and define exactly what value should be tested and

delivered by each release or by each increment.

```

```

The table below shows the state machine for the Use-Case Storytelling practice. It displays how each activity

will progress the state of the use case Alpha, or use-case slice Alpha. The table also shows how this practice

creates work products at a light (essential) level of detail, when compared to the enhanced levels of detail

produced by the Use Case Authoring practice (described later). In the Prepare a Use Case activity the Test

Scenario is chosen by the team to represent one instance of the use case. The team will identify variables

which define the user’s inputs or the system responses for that particular scenario - to test the behavior of

the system once the slice has been implemented.

```

```

Activity Achieves Use Case

State

```

```

Achieves

Use-Case

Slice State

```

```

Achieves level of

detail in the

Use-Case Narrative

work product

```

```

Achieves level of

detail in the

Supporting

Information

work product

```

```

Achieves

level of detail

in the

Test Case

work product

Describe and

Slice a Use

Case

```

```

Goal Established,

Scenario Structure

Understood

```

```

Defined Bulleted Outline

Simply Defined Test Ideas

Formulated

```

```

Prepare a

Use-Case

Slice

```

```

Scenario Structure

Understood

```

```

Prepared Bulleted Outline

Simply Defined Scenario

Chosen

```



USE-CASE 3 .0 The Guide to Succeeding with Use Cases

Page 28



```

FIGURE 14 : ACTIVITIES AND WORK PRODUCTS DEFINED BY THE USE-CASE STORYTELLING PRACTICE

```

\## 3 - Use-Case Light Modeling practice



```

Create a simple, visual model that identifies and focuses on the most valuable aspects of your system and

succinctly communicates this value to all your stakeholders. Use this practice stand-alone when:

```

```

● You’d like to create a simple overview of the value your system provides.

● You’d like to have more context for your user stories and Story Maps

This practice adds additional concepts that can be used to capture and document your Use-Case Model:

Supporting Use Cases and Use-Case Diagrams.

```

```

The table below shows the state machine for the Use-Case Light Modeling practice. It displays how each

activity will progress the state of the use case Alpha, or use-case slice Alpha. The table also shows which work

product is created or updated by an activity.

```

```

Activity Achieves Use Case

State

```

```

Achieves Use-Case

Slice State

```

```

Achieves level of detail

in the

Use-Case Model

work product

```

```

Achieves level of detail in

the

Supporting Information

work product

Find Actors and

Use Cases

```

```

Goal Established Value Established Notes Taken

```

```

Describe and

Slice a Use Case

```

```

Scenario Structure

Understood

```

```

Defined Value Established Simply Defined

```

```

Prepare a Use-

Case Slice

```

```

Scenario Structure

Understood

```

```

Prepared Value Established

(or beyond)

```

```

Simply Defined

```

```

Inspect and Adapt

the Use Cases

```

```

Goal Established or

beyond

```

```

Identified

(or beyond)

```

```

Value Established

(or beyond)

```

```

Notes Taken

(or beyond)

```



USE-CASE 3 .0 The Guide to Succeeding with Use Cases

Page 29



```

A system boundary is established implicitly by using this lightweight practice, but the model may not yet

capture a complete description of all actors and all use cases inside that system of interest.

```

```

The Use-Case Light Modeling practice does not require the authoring of any formal use-case narratives; each

use case can be used to provide more context for the identification of your user stories or Features. A

development team can brainstorm with their stakeholders what sequence of steps are required to fulfill the

use case goal, as well as any failure conditions or alternate ways to achieve the same goal. These steps can

then be used to identify a series of candidate user stories. The development team can then discuss with

stakeholders how to group those user stories together into coherent use-case slices - and so identify and

define exactly what should be tested and delivered by each release or by each increment.

```

```

Consider using the Use-Case Light Modeling practice composed together with the Use-Case Storytelling

practice as your default choice in Use Case 3.0. The Use-Case Light Modeling practice describes the “big

picture” of your system as a use-case model; the Use-Case Storytelling practice describes each use case in

your model in a structured but lightweight format.

```

```

FIGURE 15 : USE-CASE LIGHT MODELING ACTIVITIES AND WORK PRODUCTS

```



USE-CASE 3 .0 The Guide to Succeeding with Use Cases

Page 30



\## 4 - Use-Case Authoring practice



```

Evolve your Use-Case Narratives to provide a formal, detailed specification of the most critical use cases of

your system.

```

```

This practice extends the Use-Case Storytelling practice to support the use of use cases when working with

more complex business domains and safety critical systems, or when you need to support formal contracting

mechanisms.

```

```

The table below shows the state machine for the Use-Case Authoring practice. It displays how each activity

will progress the state of the use case Alpha, or use-case slice Alpha. The table also shows which work products

are created or updated by each activity.

```

```

Activity Achieves Use

Case State

```

```

Achieves Use-

Case Slice

State

```

```

Achieves level of

detail in the

Use-Case Narrative

work product

```

```

Achieves level of

detail in the

Supporting

Information

work product

```

```

Achieves

level of detail

in the

Test Case

work product

Describe and

Slice a Use

Case

```

```

Goal Established,

Scenario

Structure

Understood

```

```

Defined Briefly Described Simply Defined

Test Ideas

Formulated

```

```

Prepare a

Use-Case

Slice

```

```

Scenario

Structure

Understood

```

```

Prepared Essential Outline

Simply Defined

(or beyond)

```

```

Variables

Identified

```

```

The development team can tailor this practice and define for each use case how much information must be

created to satisfy the stakeholder’s needs. The practice describes one or more optional “enhanced” levels of

detail for the supporting information, test case and use-case narrative work products.

```

```

Optional levels of detail for work products are shown in the bottom left-hand of FIGURE 16 as grey trapezoids

with dashed lines around the boxes; mandatory levels of detail are shown by a white trapezoid with solid line

borders. Select the correct level of detail to satisfy your project or contractual requirements.

```



USE-CASE 3 .0 The Guide to Succeeding with Use Cases

Page 31



```

FIGURE 16 : USE CASE AUTHORING ACTIVITIES AND WORK PRODUCTS

```

```

Use this practice when:

```

```

● A complete, verifiable requirements specification is required for contractual or other reasons.

● When, for whatever reason, the subject matter experts and the developers will not be able to

have frequent, regular discussions with the developers about the use cases and their scenarios.

● When an area of a system is complex and / or safety critical and needs a more rigorous up-front

specification before development and testing can commence.

This practice can, of course, be used to add detail to your use-cases when starting with the Use-Case

Storytelling practice.

```

```

This practice adds additional concepts that can be used to add precision and accuracy to your Use-Case

Narratives: Supporting Information, System-Wide Requirements, Pre-Conditions, Post-Conditions, and

Extension Points.

```

```

Once again, this practice does not require the creation and or maintenance of a Use-Case Model but,

particularly where contracts are involved, it is usually combined with some form of Use-Case Modeling (light

or structured) to provide a more complete specification of a system’s use cases.

```



USE-CASE 3 .0 The Guide to Succeeding with Use Cases

Page 32



\## 5 - Use-Case Structured Modeling practice



```

Evolve your Use-Case Model to fully define the scope of your intended system and reflect its evolution over

time. This practice extends the Use-Case Light Modeling practice. It can be used to add more rigor and

completeness to your Use-Case Model if this practice is used instead of the Use-Case Storytelling practice.

```

```

Use this practice when:

```

```

● You want to capture the full system boundary (i.e. all use cases and all actors are captured).

● You want to be able to better visualize the contents of your releases.

● You want to use your use-case model as the heart of the system’s permanent record.

● You want to define different configurations and pricing options.

```

```

This practice adds additional concepts that can be used to add flexibility, precision, and accuracy to your

Use-Case Model: System Boundary (identifying the full set of known use cases that exist within the system of

interest), Include, Extend, Actor Generalization and Use-Case Generalization.

```

```

Extend is typically used when extending an existing use case to allow another use case to get access to events

occurring while executing the extended use case. Take for example the login/logout use case. If we consider

our “Browse and Shop” Use-Case Model from FIGURE 5 , when logged in, you can extend that use case with

the Browse and Shop, Maintain Inventory, Fulfill Orders and Track Orders use cases. You have to identify an

extension point in the extended use case (the login/logout use case in this example) that is used by the

extending use case (e.g. Browse and Shop) to add its behavior. Extend may be used to describe different

behaviors of the system – for example to represent different options offered to customers, the scope of

different releases, or different versions of the same system offered to customers at different price points.

Extend may also be used to represent complex error handling or exception handling – where you do not wish

for that behavior to obscure the understandability of the extended use-case.

```

```

Include may be used to split a large use case into several use cases to make it easier to understand, or to

extract some common behavior of several use cases into a separate use case.

```

```

Actor generalization identifies a relationship between one or more actors derived from a generalized actor.

It can be used to show common actor behavior.

```

```

Use-case generalization identifies a relationship between one or more use cases derived from a more general,

more abstract use case.

```

```

These additional concepts are extremely valuable, but they should only be used when they will help

stakeholders understand the big picture, and where they improve understanding and communication between

stakeholders, users and the development team.

```

```

Activity Achieves Use Case

State

```

```

Achieves Use-Case

Slice State

```

```

Achieves level of detail

in Use-Case Model

work product

```

```

Achieves level of detail

in System Information

work product

Find Actors and

Use Cases

```

```

Goal Established Identified Value Established Notes Taken

```

```

Describe and

Slice a Use Case

```

```

Scenario Structure

Understood

```

```

Defined Value Established Notes Taken

```

```

Prepare a Use-

Case Slice

```

```

Scenario Structure

Understood

```

```

Prepared System Boundary

Established (or beyond)

```

```

Simply Defined

(or beyond)

```

```

Inspect and

Adapt the Use

Cases

```

```

Goal Established

(or beyond)

```

```

Identified

(or beyond)

```

```

Value Established

(or beyond)

```

```

Notes Taken

(or beyond)

```



USE-CASE 3 .0 The Guide to Succeeding with Use Cases

Page 33



```

FIGURE 17 : USE-CASE STRUCTURED MODELING ACTIVITIES AND WORK PRODUCTS

```

\## An example of practice composition



```

Each Use-Case 3.0 practice may be used individually. But as mentioned before they may also be treated like

“building blocks” - they can be composed together to get more powerful practices.

```

```

We have already defined one composed practice: Use-Case Storytelling practice + Use-Case Light Modeling

practice. This composed practice produces four work products: a Use-Case Model which is created by the Use-

Case Light Modeling activities; the other three work products (use-case narrative, supporting information,

test cases) are created by the activities defined by the Use-Case Storytelling practice.

```

```

Use this combination of two practices when:

● You want a use-case practice light on modeling and light on description.

● You’d like to create a simple overview of the value your system provides to users and to

stakeholders.

● You want to capture the scenarios, test cases and any supporting information related to each use

case identified in the use-case model.

● You’d like to have more context for your user stories and Story Maps

```

```

This composition is a common starting point for people new to use cases as it combines the power of Use-

Case Light Modeling to find your use cases with the efficiency of Use-Case Storytelling to bring the use cases

to life.

```



USE-CASE 3 .0 The Guide to Succeeding with Use Cases

Page 34



```

Activity Achieves Use

Case State

```

```

Achieves

Use-Case

Slice State

```

```

Achieves

level of

detail in

Use-Case

Model

work product

```

```

Achieves

level of

detail in

Supporting

Information

work product

```

```

Achieves level

of detail in

Use-Case

Narrative

work product

```

```

Achieves level

of detail in

Test Case

work product

```

```

Find Actors

and Use

Cases

```

```

Goal Established Identified Value

Established

```

```

Notes Taken Briefly

Described

```

```

Test Ideas

Formulated

```

```

Describe

and Slice a

Use Case

```

```

Scenario

Structure

Understood

```

```

Defined Value

Established

```

```

Notes Taken Bulleted

Outline

```

```

Test Ideas

Formulated

```

```

Prepare a

Use-Case

Slice

```

```

Scenario

Structure

Understood

```

```

Prepared Value

Established

(or beyond)

```

```

Simply

Defined

```

```

Bulleted

Outline

```

```

Scenario

Chosen

```

```

Inspect

and Adapt

the Use

Cases

```

```

Goal Established

or beyond

```

```

Identified

(or

beyond)

```

```

Value

Established

(or beyond)

```

```

Notes Taken

(or beyond)

```

```

Briefly

Described

(or beyond)

```

```

Test Ideas

Formulated

(or beyond)

```

```

FIGURE 18 : ACTIVITIES AND WORK PRODUCTS WHEN YOU COMPOSE THE USE-CASE LIGHT MODELING PRACTICE

AND USE-CASE STORYTELLING PRACTICE TOGETHER

```



USE-CASE 3 .0 The Guide to Succeeding with Use Cases

Page 35



\## Another example of Use-Case practice composition



```

Use-Case 3.0 practices can be composed together. If the Use-Case Structured Modeling practice and Use-Case

Authoring practice are combined together, the diagram below shows the complete set of work products that

would be defined.

```

```

This comprehensive practice includes the detail of a use-case structured model, which can employ the use-

case notation of include, extend and generalization if it is helpful to do so. The use-case authoring practice

creates a formal, structured and detailed use-case narrative for each use case. Supporting information is

comprehensively defined - using formal specification techniques such as business rule catalogues, information

modeling and domain modeling - to capture and cross reference complex or voluminous data.

```

```

Use this combination of practices when you want to describe your use cases with precision and depth.

```

```

FIGURE 19 : ACTIVITIES AND WORK PRODUCTS FOR THE USE-CASE STRUCTURED MODELING PRACTICE AND USE-

```

\## CASE AUTHORING PRACTICE COMPOSITION.





USE-CASE 3 .0 The Guide to Succeeding with Use Cases

Page 36



\## Anatomy of Use-Case 3.0 Practices



\## Use Case 3.0 uses the Essence language



```

Each practice in the Use-Case 3.0 is described by:

```

```

● Things to work with (i.e. the use case and use-case slices)

● Things to do

● Things to produce

```

```

The key element is the Things to work with , which in Essence are called the Alphas. In Use Case 3.0 the

Alphas are Use Case, Use-Case Slice, and Work Item. All Alphas have states and during the lifetime on an

Alpha, it goes from state to state. Alphas can also have sub-Alphas – simple aggregation, for instance Use-

Case is a sub-alpha to Requirements, Use-Case Slice is a sub-Alpha to Use-Case, Work Item is a sub-Alpha to

Use-Case Slice. In Use Case 3.0, the states of the Work Item Alpha are defined by the development practice

selected by the team: e.g. states that describe how a user story work item, or a project task work item

progresses.

```

```

The Things to do are in Essence called Activities. Activities progress Alphas through states, and work on Work

Products.

```

```

The Things to produce are in Essence called Work Products. Work Products are created, described or

produced, and updated by Activities.

```

```

Where do these concepts of alphas, activities, work products, etc. come from? Use Case 3.0 is defined using

the OMG Essence language – which is a domain-specific language for defining practices and methods. Essence

uses a simple, visual syntax that is straightforward to use. The figure below shows a concept map for the

Essence language, and also defines the four Essence elements referenced in this document. You do not need

to understand the Essence language in order to use Use-Case 3.0, but it may be helpful to know why each

practice is structured using the four standard Essence elements described above.

```



USE-CASE 3 .0 The Guide to Succeeding with Use Cases

Page 37



```

FIGURE 20 : KEY ESSENCE LANGUAGE CONCEPTS.

```

```

FIGURE 21 shows the Alphas identified in Use Case 3.0 and how they are related to one another. It also shows

other Alphas defined outside Use-Case 3 .0 but of importance, described here:

```

```

Stakeholders are the people, groups, or organizations who affect or are affected by a system. The

requirements are what the system must do to satisfy the stakeholders. It is important to discover what is

needed from the system, share this understanding among the stakeholders and the team members, and use

it to drive the development of the new system. In Use-Case 3.0 the requirements are captured as a set of use

cases , which are scope managed and addressed as a set of use-case slices. Any changes requested by the

stakeholders result in additions or changes to the set of use cases and use-case slices.

```

```

The system is the system to be built, or a system which already exists. It could be a software system although

Use-Case 3.0 can also be used in the development of combined hardware and software cyber-physical systems,

or new businesses (where you treat the business itself as a system). It is the system that implements the

requirements and is the subject of the use-case model. The quality and completeness of the system is verified

by a set of tests. The tests also verify whether the implementation of the use-case slices has been a success.

If defects are found during testing, then their presence will prevent the completion of the use-case slice until

they have been fixed and the system improved.

```



USE-CASE 3 .0 The Guide to Succeeding with Use Cases

Page 38



```

FIGURE 21 : USE-CASE 3.0 ALPHA MAP

```

```

To create an actionable plan to implement a use case, the plan typically needs to be broken up into small,

actionable pieces of work that can be given to an individual or team to complete. If the use-case slice is

simple and straightforward enough to be easily implemented and tested within a couple of days, then there

may only be the need to create a single work item. A more complex use-case slice may require many work

items to be created – to develop and test that slice within the system.

```



USE-CASE 3 .0 The Guide to Succeeding with Use Cases

Page 39



\## Alphas



```

The subjects of Use-Case 3 .0 are the requirements, the system to be assessed or developed to meet the

requirements, and the tests used to demonstrate that the system meets those requirements. At the heart of

Use-Case 3 .0 are the use case and the use-case slice. These capture the requirements of an existing system,

and of requested changes to that system. Use cases and use-case slices also drive the development of the

system.

```

\*\*Use-Case Alpha\*\*



```

A use case is all the ways of using a system to achieve a goal of a particular user. Taken together the set of all

the use cases gives us all of the useful ways to use the system. We define a use case to be an Alpha in the

Essence language.

```

```

A use case is presented as a network of scenarios. Taken together the set of scenarios capture all the ways of

using the system to achieve the goal of the primary actor. The scenarios cover both how to successfully achieve

the goal (the basic scenario) and how to handle any problems that occur on the way (extensions). Identification

of this set of scenarios will help us to understand the use case and implement it slice by slice.

```

```

As FIGURE 22 shows, a use case undergoes several state changes from its initial

identification through to its fulfillment by the system. The states constitute

important way points in the understanding and implementation of the use

case indicating:

```

1\. Goal Established: the goal of the use case has been established

&#x20;   and its value to the user and other stakeholders is clear.

2\. Scenarios Understood: the structure of the use-case’s scenarios has

&#x20;   been understood enough for the team to start work identifying and

&#x20;   implementing the first use-case slices.

3\. Basic Scenario Enabled: when the use case’s basic scenario can be

&#x20;   successfully traversed through the system - from beginning to end.

4\. Sufficient Scenarios Fulfilled: the system fulfills enough of the use

&#x20;   case’s scenarios to provide a usable solution.

5\. All Scenarios Fulfilled: when the system fulfills all the use case’s

&#x20;   scenarios and delivers all the ways of using the system to achieve

&#x20;   the user’s goals.



```

This will be achieved by implementing the use case slice-by-slice. The states

provide a simple way to assess the progress you are making in understanding

and implementing the use case.

```

\*\*Use-Case Slice Alpha\*\*



```

We have described already that a use-case slice is a slice of a use case that provides clear value to the

development stakeholders. It includes a requirements slice specifying the interaction with its actor(s) and the

actions taken by the use case, and a test slice verifying the requirements.

```

```

FIGURE 22 : THE LIFECYCLE

OF A USE CASE

```



USE-CASE 3 .0 The Guide to Succeeding with Use Cases

Page 40



```

The important things to remember about use-case slices are that each slice:

```

```

● Traverses one or more of the use-case’s scenarios.

● Always starts with the start of the use case.

● Always ends with the termination of the use case.

● Always provides value to stakeholders: either by 1) traversing the basic scenario, or an extension

that results in the user reaching their goal, or 2) defining how an error will be handled by one or

more extension which fail to reach the user’s goal.

● Is a valuable tool for building a smaller development increment on the way to a complete release.

● Is testable and will complement the scenarios with explicit test cases.

```

```

A simple recipe for success

Applying our recipe above, use cases identify the useful things that the system will do. Select the most useful

use case to find the most useful thing that the system does. To find the most central slice you will need to

shed all the less important ways of achieving the goal and handling problems. You can do this by focusing on

the basic scenario. A slice based on the basic scenario is guaranteed to travel through the entire use case as

it will be the most straightforward way for the user to achieve their goal.

```

```

Estimate the slice and start to build it. Additional slices can then be taken from the use case until there are

enough slices to provide this particular user with a usable solution. The same can then be done for any other

use cases you need to complete a usable system.

```

```

Slicing up the use cases

The best way to find the right slices is to think about the use-case scenarios as we capture them. Each scenario

is a potential use-case slice. Each slice is defined by part of the use-case narrative and one or more of the

accompanying test cases. It is the test cases that are the most important part of the use-case slice’s

description because they make it a verifiable deliverable.

```

```

A use-case slice isn’t limited to a single scenario – often a use-case slice will focus on a number of conceptually

related scenarios (for example a set of extensions representing a set of error cases). In fact, we may create

the slice before we know the details of exactly how many extensions it will contain.

```

```

A use-case slice doesn’t need to contain an entire scenario and all its test cases; for example: the first slice

might just be the basic scenario and one test case. Additional slices can then be added to complete the basic

scenario and address all the test cases.

```

```

The use-case slicing mechanism is very flexible because it enables you to create slices as big or as small as

you need to drive the incremental development of your system.

```

```

Use-case slices make good items for scope and priority management. For example, it would be easy to apply

a prioritization scheme such as MoSCoW (Must, Should, Could, Won’t) to the slices identified above.

```

```

Use-case slices are a useful mechanism for dividing up a use case and they offer some advantages as a thinking

tool - when compared to only working with use-case scenarios and steps. Slices leave more room for evolution

(i.e. addition of more test cases or more scenarios) during design. As you become more familiar with use cases

and use-case slices you may even start to discover the slices before detailing out the individual scenarios.

```



USE-CASE 3 .0 The Guide to Succeeding with Use Cases

Page 41



```

A use case covers all the ways of achieving a goal of a particular actor. These scenarios will be of varying

importance and priority. There are often too many scenarios to deliver in a single release and generally too

many to work on in a single development increment. Because of this we need a way to divide the use case

into smaller slices that:

1\) allow us to deliver the use case in stages whilst ensuring that each stage is usable and adds to the

system behavior experienced by the user,

2\) is a suitable unit of work for the team to develop and test, and

3\) allow us to have small and similarly sized slices that flow quickly through development.

```

```

A use-case slice captures one or more scenarios through a use case that are of clear value to a stakeholder.

Typically (but not always), a use-case slice captures one of the ways of using a system to achieve a goal. They

act as a placeholder for all the work required in the slice. The use-case slice evolves to include the

corresponding slices through design, implementation, and tests.

```

```

Slices are more than just requirements and test cases

```

```

When we build the system in slices it is not enough to just slice up the requirements. Although use cases have

traditionally been used to help understand and capture requirements, they have always been about more

than this. As shown in FIGURE 23 , the use-case slice will slice through more than just the requirements and

test; it also slices through design and implementation.

```

(^)

\*\*FIGURE 23 : A USE-CASE SLICE IS MORE THAN JUST A SLICE OF THE USE CASE\*\*

On the left of \*\*FIGURE 23\*\* you can see the use-case slice, this is a slice taken from one of the use cases shown

in the next column. The slice then continues through the design showing the design elements involved, and

through the implementation where you can see which pieces of the code implement the slice. Finally, the

slice cuts through the test assets, not just encompassing the test cases, but also the test scripts used to

execute the test cases, and the test results generated.

As well as providing traceability from the requirements to the code and tests, thinking of the slices in this

way helps you develop the right system. When you come to implement a slice, you need to understand the

impact that the slice will have on the design and implementation of the system. Does it need new system

elements to be introduced? Can it be implemented by just making changes to the existing elements? If the





USE-CASE 3 .0 The Guide to Succeeding with Use Cases

Page 42



```

impact is too great you may even decide not to implement the slice! If you have the basic design for the

system this kind of analysis can be done easily and quickly and provides a great way to understand the impact

of adding the slice to the system.

```

```

By addressing each aspect of the system slice by slice, use cases help with all the different areas of the system

including user experience (user interface), architecture, testing, and planning. They provide a way to link the

requirements to the parts of the system that implement them, the tests used to verify that the requirements

have been implemented successfully, and the release and project plans that direct the development work.

```

```

As FIGURE 24 shows, a use-case slice undergoes several state changes from its initial identification through

to its final acceptance. The states constitute important way points in the understanding, implementation and

testing of the use-case slice indicating:

```

1\. Identified: the slice has been scoped and the extent of the scenarios

&#x20;   and other requirements covered is known.

2\. Defined: the extent of the slice has been clarified by identifying

&#x20;   the scenarios through the use case and how they would be verified.

&#x20;   This is done by elaborating the scenarios and identifying a set of

&#x20;   test cases to clearly define what it means to successfully implement

&#x20;   the slice. A high-level estimate has been made for the effort

&#x20;   required to prepare, implement and test the slice.

3\. Prepared: the work items required to deliver an implementation of

&#x20;   the slice have been quantified and added to a team’s backlog and

&#x20;   / or plans.

4\. Implemented: the system has been enhanced to implement the

&#x20;   slice and the slice is ready for testing.

5\. Verified: the slice has been verified as done and is ready to be

&#x20;   released to the user in the system.



```

The states provide a simple way to assess the progress you are making in

understanding and implementing the use-case slices. They also denote the

points when the slice is at rest and could potentially be handed over from

one person or team to another. To the casual observer glancing at the states, this might look like a waterfall

process: identification > definition > preparation > implementation > verification. There is a big difference,

though: In a waterfall approach, all the requirements are prepared before the preparation starts, all

preparation is completed before the implementation starts, and all implementation is completed before

verification starts.

```

```

Here we are dealing with an individual use-case slice. Across the set of slices all the activities could be going

on in parallel. While one use-case slice is being verified, another use-case slice is being implemented, a third

is being prepared, and a fourth being analyzed. In the next chapter we will explore this more when we look

at using Use-Case 3 .0 with different development approaches.

```

\*\*Why Use Cases, Use-Case Slices, and Scenarios?\*\*



```

The Use-Case Foundation defines: “A use case is all the ways of using a system to achieve a goal of a particular

user.”

```

```

All these ways, both successful and unsuccessful, are captured in the use case’s scenarios. This provides a

map of all the ways of using the system when conducting the use case, and just like a map there are many

possible scenarios through the flow of events.

```

```

The use case always starts with the user doing something that the system can detect. This is the first step of

the basic scenario and the first step of all the scenarios through the use case. Regardless of the execution

```

```

FIGURE 24 : THE LIFECYCLE

OF A USE-CASE SLICE

```



USE-CASE 3 .0 The Guide to Succeeding with Use Cases

Page 43



```

path through the use case we always end up at the final step of the basic scenario where the use case ends.

```

```

FIGURE 25 illustrates how even for a simple use case with just a few scenarios there are an exponentially

greater number of execution paths through the use case.

```

```

FIGURE 25 : THERE ARE MANY PATHS THROUGH A USE CASE

```

```

On the left of the figure the basic scenario is shown as a vertical linear sequence of steps and the extensions are

shown as detours from this set of steps. The extensions are always defined as variations on the basic scenario.

On the right of the diagram some of the scenarios through the use case are shown. Each scenario traverses

one or more flows starting with the first step of the basic scenario and terminating with the use case at the

end of the basic scenario. This ensures that all the scenarios are related to the achievement of the same goal,

are complete and meaningful, and are complementary as they all build upon the simple story described by

the basic scenario. For each scenario there will be one or more test case.

```

```

The key to finding effective slices is to understand the structure of the use case and then to group the scenarios

and their test cases into meaningful slices of value that can be used to 1) conduct the implementation on the

use case in stages and 2) to scope manage the use case and focus on the quick delivery of value. The smallest

a slice can be is a single test case traversing a single scenario through the use case. For example, it might be

too much to start with the whole of the basic scenario and you may choose to start with a single end-to-end

test case confirming if the actor has been successful in achieving their goal, and to implement an experimental

solution with hard coded values and no error handling.

```



USE-CASE 3 .0 The Guide to Succeeding with Use Cases

Page 44



```

FIGURE 26 : SLICING A USE CASE

```

```

FIGURE 26 illustrates one way of slicing up the use case with the first slice being used to represent the basic

scenario, a second slice completes the basic scenario and the extension Ext1, a third slice addressing the

other extensions. A fourth slice handles two error conditions that may be encountered by the user when

attempting to reach their goal.

```

```

Note: Slices can be functional or non-functional in nature. Non-functional slices (i.e. slices that enhance the

non-functional requirements of the system such as improving performance or enhancing security) wouldn’t

require new extensions but would be additional slices with additional test cases.

```

```

There are two common approaches to identify a use-case’s scenarios and create their use-case slices:

```

```

Top Down: Some people like to take a top-down approach where they 1) identify the use case, 2) outline the steps of

the basic scenario, and 3) brainstorm extensions based on the basic scenario. This activity creates the use

case narrative and then allows the development team to partition up the scenarios into a discrete set of slices – where

each slice contains one or more scenarios.

```

```

Bottom Up: Using the bottom-up approach, we start by brainstorming to find the critical user stories with

their goals. Each such user story is identified as one scenario of a use case. The brainstormed use cases are

then examined to identify the extensions. The use-case structure then leads us to make sure that all the

scenarios are well-formed and complementary.

```

```

You should pick the approach that works best for your stakeholders. You can of course combine the two

approaches and work both top-down, from your use cases, and bottom up from any suggested new user

stories or change requests.

```



USE-CASE 3 .0 The Guide to Succeeding with Use Cases

Page 45



\*\*Defects and Changes\*\*



```

Although not a direct part of Use-Case 3 .0, it is important to understand how defects and changes are related

to the use cases and the use-case slices.

```

```

Changes requested by the stakeholders are analyzed against the current use-case model, use cases, and use-

case slices. This enables the extent of the change to be quickly understood. For example, adding a new use case to

the system is a major change as it changes the system’s overall goals and purpose; whereas a change to an

existing use case is typically much smaller, particularly if it is to a scenario that has not been allocated to a

slice and prepared, implemented or verified.

```

```

Defects are handled by tracking which use-case slices, and by implication which test cases, result in their

detection. If they are found during the implementation or testing of a use-case slice, then that slice cannot

advance until the defect is addressed and the test(s) can be passed. If they are found later during regression

testing, then the relationship between the failed test cases and the use case(s) allow you to quickly discern what impact

the defect will have on the users and the usability of the system.

```



USE-CASE 3 .0 The Guide to Succeeding with Use Cases

Page 46



\## Work Products



```

The use case Alpha and the use-case slice Alpha produce or update a number of work products the team uses

to help share, understand, and document each use case.

```

```

FIGURE 27 : USE-CASE 3.0 WORK PRODUCTS

```



USE-CASE 3 .0 The Guide to Succeeding with Use Cases

Page 47



```

FIGURE 27 shows the full set of work products defined by the use case 3.0 practice family (each work product

is displayed with grey borders) and their relationship to:

```

\- requirements

\- the system

\- the tests required to confirm the system implements the requirements and has the necessary quality

&#x20;   attributes.



```

The Use-Case Model visualizes the requirements as a set of use cases, providing an overall big picture of the

system to be built. The model defines the use cases and provides the context for the elaboration of the individual

use cases. The use cases are explored by outlining and discussing the scenarios and any constraints that apply to them.

```

```

Each use case is described by 1) a Use-Case Narrative that outlines its scenarios and constraints (such as

standards, quality, or performance requirements) and 2) a set of Test Cases that will be used to verify the use

case and the requirements it captures.

```

```

A Use-Case Slice is one or more scenarios through one of the system’s use cases plus the relevant design,

code and tests used to implement and verify them. A use-case slice acts as a placeholder for all the work

required to deliver the value implicit in the slice. The use-case slice evolves to include the corresponding

slices through design, implementation, and test.

```

```

The use-case model is complemented by Supporting Information. This captures the definitions of the terms

used in the use-case model and when outlining the scenarios and constraints in the use-case narratives. It also

captures any system-wide requirements: those requirements that apply to all the use cases. Again, these will

influence the slices selected from the use cases and be assigned to the use-case slices for implementation.

```

```

You may be disconcerted by the lack of any explicit work products to capture and document the use-case slices. These

are not needed as they are fully documented by the other work products. If required, you can list the slices

related to a use case as an extra section in the use-case narrative but this is not essential.

```

\*\*Working with the use cases and use-case slices\*\*



```

As well as creating and tracking the work products, you will also need to track the states and properties of

the use cases and the use-case slices. This can be done in many ways and in many tools. The states can be

tracked very simply using sticky notes or spreadsheets. If more formality is required one of the many commercially

available application lifecycle management, work management, requirements management, change management or

defect tracking tools could be used. FIGURE 2 8 shows a use case and some of its slices captured on a set of sticky

notes.

```



USE-CASE 3 .0 The Guide to Succeeding with Use Cases

Page 48



```

FIGURE 28 : CAPTURING THE PROPERTIES OF A USE CASE AND ITS SLICES USING STICKY NOTES

```

```

The use case shown is the ‘Browse and Shop’ use-case from an on-line shopping application. Slice 1 and slice

2 of the use case are derived from the basic scenario: ‘Select and buy 1 Product’ and ‘Select and buy 100

Products’. Slice 3 is based on multiple scenarios covering the availability of the various support systems

involved in the use case. In the example shown above, Browse and Shop is Use Case #7 – represented by the light blue

sticky note. Each slice is represented by a yellow sticky note, numbered on the top-left corner as 7.1, 7.2, etc.

```

```

The essential properties for a use case are its name, state, and priority. In this case the popular MoSCoW

(Must, Should, Could, Would) prioritization scheme has been used. The use cases should also be estimated. In

this case a simple scheme of assessing their relative size and complexity has been used.

```

```

The essential properties for a use-case slice are 1) a meaningful name, 2) references to the use case and the

scenarios it covers, 3) references to the tests and test cases that will be used to verify its completion, and 4)

an estimate of the work needed to implement and test the slice. There must also be a reference to each of

the work items (e.g. user stories, or Features, or Tasks) used to implement that slice. In this example the

reference to the use case is implicit in the slices number and list of scenarios. The estimates have been added

later after consultation with the team. These are the numbers towards the bottom right of each sticky note on

FIGURE 2 8. In this case the team has played planning poker to create relative estimates using story points; 5

story points for slices 7.1 and 7.2, and 13 story points for slice 7.3 which the team believe will take more

than twice the effort of the other slices. Alternatively ideal days, t-shirt sizing (XS, S, M, l, Xl, XXl, XXXl), or

any other popular estimating technique could be used.

```

```

The use cases and the use-case slices should also be ordered so that the most important ones are addressed

first. FIGURE 2 9 shows how these sticky notes can be used to build a simple product backlog on a white board.

Reading from left to right you can see 1) the big picture illustrated by use-case diagrams showing the scope

of the complete system and the first release, 2) the use cases selected for the first release and some of their

slices which have been identified but not yet detailed and ordered, 3) the ordered list of slices ready to be

developed in the release and finally 4) those slices that the team have successfully implemented and verified.

```



USE-CASE 3 .0 The Guide to Succeeding with Use Cases

Page 49



```

FIGURE 29 : USING USE CASES AND USE-CASE SLICES TO BUILD A BACKLOG

```

```

FIGURE 2 9 is included for illustrative purposes only, there are many other ways to organize and work with your

requirements. For example, many teams worry about their sticky notes falling off the whiteboard. These

teams often track the state of their use cases and use-case slices using a simple spreadsheet including work-

sheets such as those shown in FIGURE 30 and FIGURE 31 below.

```

```

FIGURE 30 : EXAMPLE - USE-CASE TRACKING WORKSHEET

```



USE-CASE 3 .0 The Guide to Succeeding with Use Cases

Page 50



```

FIGURE 31 : EXAMPLE - USE-CASE SLICE TRACKING WORKSHEET

```

```

These illustrations are included to help you get started. The use cases and the use-case slices are central to

everything the team does, so use whatever techniques you need to make them tangible and visible to the

team. Feel free to add other attributes as and when you need them, for example to record the source of the

use case or its owner, or to target the use-case slices on a particular increment within the release.

```

\*\*Completing the Work Products\*\*



```

As well as tracking the use cases and the use-case slices you will need to, at least, sketch out and share the

related work products.

```

```

All the work products are defined with a number of levels of detail. The most important level of detail defines

the essentials, the minimal amount of information that is required for the practice to work. Further levels of

detail help the team cope with any special circumstances they might encounter. For example, this allows

small, collaborative teams to have very lightweight use-case narratives defined on simple index cards and

large distributed teams to have more detailed use-case narratives presented as documents. The teams can

then grow the narratives as needed to help with communication, or thoroughly define the important or safety

critical requirements. It is up to the team to decide whether they need to go beyond the essentials, adding

detail in a natural fashion as they encounter problems that the bare essentials cannot cope with.

```

```

In some cases, there will be an additional level of detail that is used to establish a sketch of the work product

prior to the completion of the essentials. For example, a use case narrative may be briefly described when

the use case if found and then further evolved to create the bulleted outline once it is decided that the use

case is in scope.

```

```

FIGURE 32 shows the levels of detail defined for the full set of Use-Case 3 .0 work products. The lightest level

of detail is shown at the top of the table. The amount of detail in the work product increases as you go down

the columns enhancing and expanding the content.

```



USE-CASE 3 .0 The Guide to Succeeding with Use Cases

Page 51



```

FIGURE 32 : WORK PRODUCT LEVELS OF DETAIL

```

```

The good news is that you always start in the same way, with a sketch that evolves to cover the essentials.

The team can then continually adapt the level of detail in their use-case narratives to meet their emerging

needs. Work products can be enhanced and expanded (but only when necessary) - by adding optional levels of detail. The

optional levels of detail are represented in the figure above by the grey boxes with dashed-line borders. The level of

detail can also be adjusted to reduce waste; anything beyond the essentials should have a clear reason for

existing or be eliminated. As Einstein (is attributed to have) said “Everything should be made as simple as

possible, but not simpler”.

```

```

For more information on the work products and their levels of detail see Appendix 2 : Work Products.

```



USE-CASE 3 .0 The Guide to Succeeding with Use Cases

Page 52



\## Activities



```

Use-Case 3 .0 breaks the work up into a number of essential activities the team must complete. Things to do

represent Essence Activities in the Essence language. These activities are shown in FIGURE 33 where they are grouped

into two sets: 1) those activities used to discover, order and verify the requirements, and 2) those activities

used to shape, implement and test the system. The solid chevrons indicate activities that are explicitly

defined by Use-Case 3.0. The dashed chevrons are placeholders for other activities that the practice depends

on to be successful. Use-Case 3 .0 does not specify how these activities are performed, it just needs them to be

done.

```

```

FIGURE 33 : THE ACTIVITIES IN USE-CASE 3.0

```

```

Read FIGURE 33 from left to right to get an impression of the order in which the activities are first performed.

The activities themselves will all be performed many times in the course of your work. Even a simple activity

such as ‘Find Actors and Use Cases’ may need to be performed many times to find all the use cases, and may

be conducted in parallel with, or after, the other activities. For example, whilst continuing to ‘Find Actors

and Use Cases’ you may also be implementing some of the slices from those use cases found earlier.

```

```

The rest of this chapter introduces each of the activities, following the journey of a use-case slice from the

initial identification of its parent use case through to its final testing and inspection. The next chapter includes

a brief discussion on how to organize the activities to support different development approaches such as Scrum,

Kanban, Iterative and Waterfall.

```



USE-CASE 3 .0 The Guide to Succeeding with Use Cases

Page 53



\*\*Find Actors and Use Cases\*\*



```

First you need to find some actors and use cases to help you to:

```

```

● Agree on the goals of the system.

● Agree on new system behavior.

● Scope releases of the system.

● Agree on the value the system provides to users.

● Identify ways of using and testing the system.

```

```

One way to do this is to hold a use-case modeling workshop with

your users. There is no need to find all the system’s use cases at

once, just focus on those that are going to achieve the goals of

those users. Other actors and use cases might be found later on as you

inspect and adapt the use cases.

```

```

As the use cases are discovered they should be ordered to support

the team’s release plans. Use cases enable high-level scope

management without the need to discover or author all the use-

cases' scenarios. If a use case isn’t needed, then there is no need

to discuss or document its scenarios. If the use case is in scope, it

should be outlined (or be fully described) so that there is enough

information to understand the use cases and to start the slicing work.

```

```

Repeat this activity as necessary to evolve your model and find any

missing actors or use cases.

```

```

TIP: MODEL STORM TO KICK START

YOUR USE-CASE MODEL

```

```

The formal nature of the use-case

model, and its use of the Unified

Modeling Language, can be a barrier to

involving users and other stakeholders

in the modeling effort.

```

```

A great way to overcome this is to

simply get the users together to

brainstorm the different types of users

and their goals using sticky-notes

(vertical for users and horizontal for

goals.) Then facilitate the grouping of

these into actors and use cases, which the

team will then find very easy to

quantify, outline, and order.

```



USE-CASE 3 .0 The Guide to Succeeding with Use Cases

Page 54



\*\*Describe and Slice a Use Case\*\*



```

Next you need to build your understanding of the use case and

create your first use-case slices. The development team will do

this to:

```

```

● Align with users on the scope of the use case and its

scenarios.

● Create suitably sized work items for the team to

work on.

● Fit within the time and budget available.

● Deliver the highest value to users, and other

stakeholders.

● Demonstrate critical project progress or

understanding of needs.

Even the simplest use case will cover several scenarios to

achieve the goal. The development team will need to slice the

use case to select the scenario(s) to be implemented. You

should do the slicing with users to make sure that the slices

created are valuable to users and are worth implementing.

Don’t slice up all the use cases at once. Just focus on the use

cases to be worked in immediately.

```

```

You don’t need to completely slice up the use case, just pull

out the slices that are needed to progress the work and leave

the rest of the use case for slicing when and if it is needed. A

slice may improve the non-functional characteristics of the

system, such as a performance improvement, or an architectural

change. You can even adopt a pull model where the developers

ask for new slices to be identified as and when they have the

capacity to implement them.

```

```

The slices created should be sequenced for delivery to make sure the development team tackles them in the right

order. The team should do this with your users to make sure that the ordering defines the smallest usable system

possible. The best way to do this is to consider the combination of priority, value, risk, and necessity.

```

```

Repeat this activity whenever new slices are needed.

```



USE-CASE 3 .0 The Guide to Succeeding with Use Cases

Page 55



\*\*Prepare a Use-Case Slice\*\*



```

Once a slice is selected for development more work is required

to:

● Get it ready for implementation.

● Estimate the effort required to implement and test the

slice.

● Clearly define what it means to successfully

implement the slice.

● Define required characteristics (i.e. non-functional

requirements).

● Focus the development of the system towards the tests

it must meet.

● Split it up into a set of smaller work items (for

example, user stories, features, or tasks) that can be

integrated into the team’s backlog and plans.

```

```

Preparing a use-case slice is a collaborative activity, you need

input from the users, the stakeholders who approve the

investment to implement the slice, developers, and testers to

clarify the use-case narrative and define the test cases. When

preparing a use-case slice you should focus on the needs of the

developers and testers who will implement and verify the slice.

```

```

Think about how they will access the information they need.

Will they be able to talk to subject matter experts to flesh out

the requirements, or will they need everything to be

documented for them? You also need to balance the work

between the detailing of the use-case narrative and the

detailing of the test cases. The more detail you put in the use-

case narrative the easier it will be to create the test cases. On

the other hand the lighter the use-case narrative the less

duplication and repetition there will be between it and the test

cases. You should create the use-case narrative and the test

cases at the same time, so that the authors can balance their

own needs, and those of their stakeholders.

```

```

Think about how to split the work up into a set of smaller work

items (for example, user stories, features, or tasks) that can be

integrated into the team’s backlog and plans. For example, the

slice will probably touch on many of the system’s components or

span many steps. In both cases it may be possible for each of these

changes to be done independently or in parallel. The end-to-end

testing of the slice will make sure that everything is pulled

together and integrated before the slice is considered done.

```

```

Perform this activity at least once for each slice. Repeat this

activity whenever there are changes applied to the slice.

```

```

TIP: FOR AGILE TEAMS SPLIT THE SLICE UP INTO

A SET OF SMALL, ACTIONABLE USER STORIES

```

```

Use-Case Slices generally involve many steps

and changes to many different parts of the

system because of this they usually require

more than a few days effort to complete. This

makes them too large to meet the definition

of ready used by many Agile teams particularly

those used to using user stories.

```

```

The good news is that Use-Case Slices can

easily be split up into a set of user stories –

for example each step can be presented as

a user story. For example Step 1: As a

customer I want to withdraw a standard

amount of cash so that I can go shopping ,

Step 2: As a Bank I want to check that the

funds are available so that the customer

does not go overdrawn. The same logic can

also be applied to each extension; for

example Alt 1: As a Bank I want to offer

Customers in good standing an overdraft if

they have insufficient funds to fulfill their

requested withdrawal so that they are

happy with our service.

```

```

The Use-Case Slice can act as the team goal.

```

```

TIP: IF THE SLICE HAS NO TEST CASES, THEN IT

HAS NOT BEEN PROPERLY PREPARED

```

```

When you prepare a use-case slice do not

forget to define the test cases that will be

used to verify it. It is by looking at the test

cases that we know what really needs to be

achieved.

```

```

The test cases provide the developers with

an empirical statement of what the system

needs to do. They will know that the

development of the slice is not completed

until the system successfully passes all the

test cases.

```



USE-CASE 3 .0 The Guide to Succeeding with Use Cases

Page 56



\*\*Implement the Slice\*\*



```

You are now ready to design, code, unit test, and integrate the components needed to implement a use-case

slice.

```

```

The system will be developed slice-by-slice, with different team members working in parallel on different

components or related work items.

```

\*\*Test the Slice\*\*



```

Next, independently test the system to verify that the use-case slice has been implemented successfully. This

is done by successfully executing the slice’s test cases. The independence of the use-case slices enables you

to test it as soon as it is implemented and provide immediate feedback to the developers.

```

```

Use-case 3 .0 works with most popular testing practices. It can be considered a form of test-driven

development as it creates the test cases for each slice before the slice is given to the developers for

implementation.

```

\*\*Test the System (as a Whole)\*\*



```

It is not sufficient to just test each slice as it is completed. The whole of the system needs to be tested to

verify that it correctly implements all the new use-case slices without breaking any other parts of the system.

```

```

The test cases produced using Use-Case 3 .0 are robust and resilient. This is because the structure of the use-

case narratives results in independently executable, scenario-based test cases.

```



USE-CASE 3 .0 The Guide to Succeeding with Use Cases

Page 57



\*\*Inspect and Adapt the Use Cases\*\*



```

You also need to continuously tune and evaluate the use-case

model, use cases, and use-case slices to:

● Handle changes.

● Track progress.

● Fit your work within the time and budget available.

● Keep the use-case model up to date.

● Tune the size of the slices to increase throughput.

As the work progresses it is essential that you continually

evolve your use-case model, use cases and use-case slices.

Priorities change, lessons are learnt, and changes are

requested. These can all have an impact on the use cases and

use-case slices that have already been implemented, as well

as those still waiting to be progressed. This activity will often

lead to the discovery of new use cases and the refactoring of

the existing use cases and use-case slices.

```

```

The varying demands of the project may need you to tune your

use of Use-Case 3 .0 and adjust the size of the slices or the

level of detail in your use-case narratives, supporting

information and test cases. It is important that you continually

inspect and adapt your way-of-working as well as the use cases and use-case slices you are working with.

```

```

Perform this activity as needed to maintain your use cases and handle changes.

```

```

TIP: DON’T FORGET TO MAINTAIN YOUR

BACKLOG OF USE-CASE SLICES

```

```

By ordering your slices and tracking their

state (defined, prepared, implemented,

verified) you create a backlog of the

requirements left to implement. This list

should be continually monitored and

adjusted to reflect the progress of the team

and the desires of the stakeholders.

```

```

As the work progresses you should monitor

and adjust the slice size to eliminate waste

and improve the team’s effectiveness.

```



USE-CASE 3 .0 The Guide to Succeeding with Use Cases

Page 58



\## Using Use-Case 3.0



```

Use-Case 3 .0 can be used in many different contexts to help produce many different kinds of system. In this

chapter we look at using use cases for different kinds of system, different kinds of requirements and different

development lifecycles.

```

```

It can also be used to complement and improve the results that team’s get from using complementary product

development, requirements, and work management practices such as user stories, Features, and Task-based

planning.

```

\## Use-Case 3.0: Applicable for all types of system



```

Many people think that use cases are only applicable to user-intensive systems where there is a lot of

interaction between the human users and the system. This is strange because the original idea for use cases

came from telecom switching systems, which have both human users (subscribers, operators) and machine

users, in the form of other interconnected systems. Use cases are of course applicable for all systems that

are used – and that means of course all systems.

```

\*\*Use-Case 3 .0: It’s not just for user-intensive applications\*\*



```

Use cases are just as useful for embedded systems with little or no human interaction as they are for user

intensive ones. Nowadays, people are using use cases in the development of all kinds of embedded software

in domains as diverse as the motor, consumer electronics, military, aerospace, and medical industries. Even

real-time process control systems used for chemical plants can be described by use cases where each use case

focuses on a specific part of the plant’s process behavior and automation needs.

```

```

All that is needed for use cases to be appropriate is for the system to collaborate with the outside world,

regardless of whether the users are humans or other systems. Their applicability is far broader than most

people think.

```

\*\*Use-Case 3 .0: It’s not just for software development\*\*



```

The application of use cases is not limited to software development. They can also help you to understand

your business requirements, analyze your existing business, design new and better business processes, and

exploit the power of IT to transform your business. By using use cases recursively to 1) model the business

and its interactions with the outside world and 2) model the systems needed to support and improve the

business you can seamlessly identify where the systems will impact on the business and which systems you

need to support the business.

```

```

The use cases used to model the business are often referred to as business use cases. They provide the context

for your IT systems development work, allowing the business development and the IT development to be

carried out in perfect synchronization. Not only can you develop the IT systems slice-by-slice, but you can

also develop your business model slice-by-slice. This is very powerful as it allows you to evolve your business

and its supporting systems in tandem with one another, enabling incremental business development as well

as incremental systems development.

```

```

In the modern world the business and the IT systems that support it can, and should, be developed in synch

(one won’t work without the other). The use of use cases and use-case slices at both the business and IT

boundaries can close the gap between the business and the IT enabling them to work as truly collaborative

partners.

```



USE-CASE 3 .0 The Guide to Succeeding with Use Cases

Page 59



\## Non-functional requirements



```

Although they are one of the most popular techniques for describing a systems’ functionality, use cases are

also used to explore their non-functional characteristics. The simplest way of doing this is to capture them as

part of the use cases themselves. For example, relate performance requirements to the time taken between

specific steps of a use case or list the expected service levels for a use case as part of the use case itself.

```

```

Some non-functional characteristics are more subtle than this and apply to many, if not all, of the use cases.

This is particularly true when building layered architectures including infrastructure components such as

security, transaction management, messaging services, and data management. The requirements in these

areas can still be expressed as use cases – separate use cases focused on the technical usage of the system.

We call these additional use cases infrastructure use cases as the requirements they contain will drive the

creation of the infrastructure that the application will run on. These use cases and their slices can be

considered as cross-cutting concerns that will affect the behavior of the system when the more traditional

functional use cases are performed. For example, a use case could be created to explore how the system will

manage database transactions including all the different usage scenarios such as the schemes for data locking,

data caching, commit and roll-back. This use case would apply every time another use case retrieves or stores

data in the system.

```

```

Combining these infrastructure use cases with other techniques such as separation of concerns and aspect-

oriented programming allows these common requirements to be addressed without having to change the

implementation of the existing functional use cases.

```

\## Use-Case 3.0: Applicable for all development lifecycles



```

Use-Case 3 .0 works with all popular software development lifecycles including:

```

1\. Iterative, backlog-driven approaches such as Scrum, EssUP and openUP and their scaled

&#x20;   equivalents such as SAFe, Scrum@Scale, LeSS and Nexus.

2\. One-piece flow-based lifecycles such as Kanban

3\. All-in-one go lifecycles such as Waterfall

In the following 3 short sections we will illustrate how Use-Case 3 .0 and, in particular, use-case slices can

help with each of these. These sections are not as self-contained as the rest of the document and rely upon

the reader having a basic understanding of the approach being discussed. We recommend that you only read

the sections for the approaches you are familiar with.



\*\*User Stories as Work Items\*\*



```

Many development teams use user stories in a prioritized backlog as work items to drive their work. Here is

an example that demonstrates how user stories can be derived easily from a use-case slice, in this example

we will refer to the first use-case slice from the use case displayed in FIGURE 34.

```

```

The steps described by our use-case narrative for this slice provide an input which the developers can review

and brainstorm the user stories needed to action the slice. Each step is likely to be represented by one or

more user stories.

```

```

Optionally we could arrange the stories into a story map to illustrate the relationship between each step in

the use-case narrative, and the story (or stories) which will implement that step. The steps of the basic

scenario could be laid out from left to right to create a backbone for the Story Map; stories could be laid out

underneath the relevant step. FIGURE 34 shows the results from the initial brainstorm, laid out as a story

map.

```



USE-CASE 3 .0 The Guide to Succeeding with Use Cases

Page 60



```

FIGURE 34 : BRAINSTORMING USER STORIES FOR A SLICE

```

```

There are some interesting things to observe about this set of user stories:

```

1\. There are some technical stories to prepare the ground for implementing the steps in the basic

&#x20;   scenario or extensions (these are the two pink stories at the left of the figure). In this case the

&#x20;   team has decided to do a technical spike to integrate the two supporting systems and to do a

&#x20;   design spike to create some wireframes to look at the shopping experience.

2\. There is a technical story to ensure the end-to-end integration testing of the slice as a whole.

&#x20;   (this is the pink story on the right of the figure). This will be in addition to the developer testing

&#x20;   of each individual user story. If you are adopting a test-driven approach the creation and

&#x20;   automation of these tests will be the first thing the team does.

3\. In the above example, the purple item on the left-hand side represents the initial trigger when

&#x20;   the primary actor initiates the use case slice by interacting with the system. The purple items on

&#x20;   the right-hand side represent the goal of the slice for the user, and for the business that owns

&#x20;   the system. Purple items on this Story Map are not stories.

The whole team will typically work together with subject matter experts and their users to identify stories.

Laying out the user stories in relationship to the scenarios being addressed can keep the development team’s

Work Items connected to the original use case.



\*\*Use-Case 3 .0 and backlog-driven iterations\*\*



```

Before adopting any backlog-driven approach you must understand what items will go in the backlog. There

are various forms of backlog that teams use to drive their work including product backlogs, release backlogs,

team backlogs and project backlogs. Regardless of the terminology used they all follow the same principles.

The backlog itself is an ordered list of everything that might be needed and is the single source of

requirements for any changes to be made. The basic concept of a backlog is illustrated by FIGURE 3 5.

```



USE-CASE 3 .0 The Guide to Succeeding with Use Cases

Page 61



```

FIGURE 35 : A BASIC BACKLOG

```

```

When you use Use-Case 3.0 the use-case slices can be used as the team’s primary backlog item type. Or, if

you choose to use user stories, then user stories derived from a use-case slice would instead be placed into

the backlog. The use of use-case slices ensures that your backlog items are well-formed, as they are naturally

independent, valuable, and testable. The structuring of the use-case narrative that defines them makes sure

that they are estimable and negotiable, and the use-case slicing mechanism enables you to slice them as

small as you need to support your development team.

```

```

The use cases are not put into the ordered list themselves as it is not clear what this would mean. Does it

mean that this is where the first slice from the use case would appear or where the last slice from the use

case would appear? If you want to place a use case into the list before slicing just create a dummy slice to

represent the whole use case and insert it into the list.

```

```

When you adopt a backlog-driven approach it is important to realize that the backlog is not built and

completed up-front but is continually worked on and refined, something that is often referred to as refining

or maintaining the backlog. The typical sequence of activities for a backlog-driven, iterative approach is

shown in FIGURE 36.

```



USE-CASE 3 .0 The Guide to Succeeding with Use Cases

Page 62



```

FIGURE 36 : USE-CASE 3.0 ACTIVITIES FOR ITERATIVE DEVELOPMENT APPROACHES

```

```

Before the development starts the initial backlog is prepared. ‘Find Actors and Use Cases’ is used to build the

initial use-case model and scope the system, ‘Describe and Slice a Use Case’ is used to create the initial set

of most important use-case slices to seed the backlog. Remember: you can choose whether to create one or

more user stories to place in the backlog from each use-case slice, or instead just use the use-case slices as

backlog items.

```

```

Once the backlog is up and running you can start the first development iteration. Every iteration starts with

some planning. During this planning you need to ‘Describe and Slice the Use Cases’ to further slice the selected

use-case slices to make sure they are small enough to complete in the iteration and ‘Prepare a Use-Case Slice’

to create the work items to populate the iteration’s plan. The development team then uses ‘Implement

System (for a slice)’, and ‘Test the System (for a slice) to develop the identified slices and add them to the

system.

```

```

While the development is on-going the team also uses ‘Inspect and Adapt the Use Cases’, ‘Describe and Slice

a Use Case’ and ‘Prepare a Use-Case Slice’ to maintain the backlog, handle change and make sure there are

enough backlog items ready to drive the next iteration. The team may even need to use ‘Find Actors and Use

Cases’ to handle major changes or discover more use cases for the team. In Scrum it is recommended that

teams spend 5 to 10 per cent of their time maintaining their backlog. This is not an inconsiderable overhead

for the team, and Use-Case 3.0 provides the work products and activities needed to do this easily and

efficiently.

```

```

Finally at the end of the iteration the team needs to demonstrate the system and reflect on their performance

during the iteration. The team should use ‘Test the System (as a whole)’ to understand where they are, and

‘Inspect and Adapt Use Cases’ to reflect on the quality and effectiveness of their use cases and use-case

slices.

```

\*\*Complementing a Story Backlog with Use-Cases and Use-Case Slices\*\*



```

As discussed throughout this document, primarily in The Use-Case Foundation and Prepare a Use-Case Slice

Sections, use-case slices generally involve many steps and changes to many different parts of the system and

need to be split into a series of smaller work items for insertion into a team’s plans or story backlog. Teams

can create user stories to describe these changes. As such, Use-Case 3.0 is 100 % compatible with teams that

are already using user stories.

```



USE-CASE 3 .0 The Guide to Succeeding with Use Cases

Page 63



```

For example:

```

4\. For teams using Scrum with a user story backlog the use cases and use-case slices will help

&#x20;   them find the right user stories to populate their backlogs and focus on delivering true user

&#x20;   value. They will also help them form more effective Product and Sprint Goals.

5\. For teams using Epics (big stories) to complement their user stories (the smaller stories that

&#x20;   they take into their Sprints or Iterations) then the slices work perfectly as Epics.



\*\*Use-Case 3 .0 and one-piece flow\*\*



```

One-piece flow is an approach that avoids the batching of the requirements seen in the iterative and waterfall

approaches. In a one-piece flow approach each requirements item flows through the development process. One-piece

flow is a technique taken from lean manufacturing. FIGURE 37 : BASIC ONE-PIECE FLOW shows a small team

engaging in one-piece flow passing each item directly from workstation A to B to C.

```

```

People icons © ioannis kounadeas / Fotolia

```

```

FIGURE 37 : BASIC ONE-PIECE FLOW

```

```

For this to work effectively you need small, regularly sized items that will flow quickly through the system.

For software development the requirements are the raw materials and working software is the finished goods. Use

cases would be too irregularly sized and too big to flow through the system. The time at stations A, B and C

would be too unpredictable and things would start to get stuck. Use-case slices though can be sized

appropriately and tuned to meet the needs of the team. FIGURE 38 illustrates one-piece flow for system

development with use-case slices. Note that in Use Case 3.0 you can use the use-case slices as work items, but

if the development team wants instead to use user stories, or tasks – then each slice can be broken down into

one or more user stories (or tasks) by that team instead.

```

```

People icons © ioannis kounadeas / Fotolia

```

```

FIGURE 38 : ONE-PIECE FLOW FOR SYSTEM DEVELOPMENT WITH USE-CASE SLICES

```



USE-CASE 3 .0 The Guide to Succeeding with Use Cases

Page 64



```

As well as flowing quickly through the system, there needs to be enough items in the system to keep the team

busy. One-piece flow doesn’t mean that there is only one requirements item being worked on at a time or

that there is only one piece of work between one workstation and the next. Work in progress limits are used

to level the flow and prevent any wasteful backlogs from building up.

```

```

One-piece flow doesn’t mean that individuals only do one thing and only work at one workstation. For example

there could be more people working in Development than there are in Test, and if things start to get stuck

then the people should move around to do whatever they can to get things moving again. If there are no use-

case slices waiting to be tested but there are slices stuck in preparation, then the testers can show some

initiative and help to do the preparation work. In the same way you are not limited to one person at each

workstation, or even only one instance of each workstation.

```

```

Kanban boards are a technique for visualizing the flow through a production line. A Kanban is a sign, flag, or

signal within the production process to trigger the production and supply of product as part of just-in-time

and lean manufacturing. On a Kanban board Kanban cards are used to represent the items in the system.

Figure 39 shows a simple Kanban board for a development team which first analyses each slice to understand

its impact, then develops and unit tests the software, and finally independently tests the resulting software

before putting it live.

```

```

FIGURE 39 : USE-CASE SLICES ON A KANBAN BOARD

```

```

The work in progress limits are shown in red. Reading from left to right you can see that slices have to be

identified and scoped before they are input to the team. Here there is a work in progress limit of 5, and the

customers, product owner or business requirements team that are the source of the requirements try to keep

5 use-case slices ready for implementation at all times.

```

```

Slices are pulled from the input queue into the preparation area where impact analysis is undertaken, slices

are clarified, and the test cases finalized. Here there is a work in progress limit of 3 items. Items in the on-

going column are currently being worked on. The items in the done column have had their preparation

completed and are waiting to be picked up by a developer. In this way the slices work their way through the

development team and after successfully passing the independent system testing go live. A work in progress

limit covers all the work at the station, including both the on-going and done items. There is no work in

progress limit on the output or the number of items that can go live.

```



USE-CASE 3 .0 The Guide to Succeeding with Use Cases

Page 65



```

An important thing to note about Kanban is that there is no definitive Kanban board or set of work in progress

limits; the structure of the board is dependent on your team structure and working practices. You should tune

the board and the work in progress limits as you tune your practices. The Alpha states for the use-case slices

are a great aid to this kind of work design. FIGURE 40 shows the alignment between the states and the Kanban

board shown in FIGURE 39. The states are very powerful as they clearly define what state the slice should be

in when it is to be handed on to the next part of the chain.

```

```

FIGURE 40 : ALIGNING THE STATES OF THE USE-CASE SLICE TO THE KANBAN

```

```

FIGURE 41 shows where the different Use-Case 3 .0 activities are applied. The interesting thing here is that

“Inspect and Adapt Use Cases” is not the responsibility of any particular workstation but is conducted as part

of the regular quality control done by the team. This activity will help the team to tune the number and type

of workstations they have as well as their work in progress limits.

```

```

FIGURE 41 : USE-CASE 3.0 ACTIVITIES FOR ONE-PIECE FLOW

```



USE-CASE 3 .0 The Guide to Succeeding with Use Cases

Page 66



```

For example, as a result of reviewing the team’s effectiveness you might decide to eliminate the preparation

workstation and increase the work in progress limits for development and system test. Again, you exploit the

states of the use-case slice to define what it means for each workstation to have finished their work resulting

in the Kanban board shown in FIGURE 42.

```

```

FIGURE 42 : THE TEAM'S REVISED KANBAN BOARD SHOWING COMPLETION STATES

```

\*\*Use-Case 3 .0 and waterfall\*\*



```

For various reasons you may find that you need to develop your system within the constraints of some form

of waterfall governance model. This typically means that some attempt will be made to capture all the

requirements up-front before they are handed over to a third-party for development.

```

```

When you adopt a waterfall approach the use cases are not continually worked on and refined to allow the

final system to emerge but are all defined in one go at the start of the work. They then proceed in perfect

synchronization through the other development phases, all of which focus on one type of activity at a time.

The typical sequence of activities for a waterfall approach is shown in FIGURE 43.

```



USE-CASE 3 .0 The Guide to Succeeding with Use Cases

Page 67



```

FIGURE 43 : USE CASE 3.0 ACTIVITIES FOR WATERFALL APPROACHES

```

```

Even within the strictest waterfall environment there are still changes happening during the development of

the system itself. Rather than embrace and encourage change, waterfall projects try to control change. They

will occasionally ‘Inspect and Adapt the Use Cases’ when there is a change request that cannot be deferred,

and they will prepare additional use-case slices to handle any changes that are accepted. They are unlikely

to find any further use cases after the requirements phase as this would be considered too large a change in

scope.

```

```

The ‘one activity at a time’ nature of the waterfall approach means that the make-up of the team is

continually changing over time, and so the ability to use to face-to-face communication to share the stories

is very limited. To cope with this you need to turn up the level of detail on the work products, going way

beyond the bare essentials. FIGURE 44 shows the level of detail typically used on waterfall projects.

```



USE-CASE 3 .0 The Guide to Succeeding with Use Cases

Page 68



```

FIGURE 44 : LEVELS OF DETAIL FOR THE WORK PRODUCTS WHEN USING A WATERFALL APPROACH

```

```

Within each of the development phases one or more of the work products are progressed to a very high-level

of detail to ensure that they are 1) complete and 2) answer any and all questions that might arise during the

later phases. In the requirements phase the use-case model is worked and re-worked to make sure that all

the use cases have been discovered, all the use-case narratives are fully described and the supporting

information is comprehensively defined. At this stage some thought will be put into testing and the test ideas

formulated. The test cases are then put to one side until the test phase is reached.

```

```

The use cases and their supporting information are handed over to the design team who will assign

responsibilities to the system elements and then to define all the interactions. Eventually coding will start

and all the use cases and use-case slices will be implemented. Finally, the testers will get involved and all

the test cases will be defined in detail and testing will commence.

```

```

The sequential nature of this way-of-working may lead you to think that there is no role for use-case slices to

play, and that just handling the entire use cases would be enough. This is not true as the finer grained control

provided by the use-case slices allows the requirements team to be much more specific about the actual

scope of the system to be built. Even in waterfall projects it is unlikely that you will need all the slices from

all of the use cases. They will also help you to handle any last-minute changes in scope caused by schedule

or quality problems.

```



USE-CASE 3 .0 The Guide to Succeeding with Use Cases

Page 69



\*\*Tasks as Work Items\*\*



```

If the team is adopting a more task driven approach (e.g. using a project to deliver the work), then you could

end up with something more like this:

● Task 1 – Design Screen

● Task 2 – Implement Stock Control Interface

● Task 3 – Implement Payment System Interface

● Task 4 – Set up the Middleware

● Task 5 – Code and Unit Test – UI

● Task 6 – Code and Unit Test – Business Objects

● Task 7 – Integration Test

● Task 8 – System Test

```

\*\*Use-Case 3 .0 – It’s not just for one type of team\*\*



```

Another important aspect of Use-Case 3 .0 is its ability to adapt to existing team structures and job functions

whilst encouraging teams to eliminate waste and increase efficiency. To this end Use-Case 3 .0 does not pre-

define any particular roles or team structures, but it does define a set of states for each of the central

elements (the use case and the use-case slice).

```

```

As illustrated by the discussion on Use-Case 3 .0 and one-piece flow, the states indicate when the work items

are at rest and could be handed-over from one person or team to another. This allows the practice to be used

with teams of all shapes and sizes from small cross-functional teams with little or no handovers to large

networks of specialist teams where each state change is the responsibility of a different specialist. Tracking

the states and handovers of these elements allows the flow of work through the team (or teams) to be

monitored, and teams to adapt their way-of-work to continuously improve their performance.

```

\## Use-Case 3.0: Scaling to meet your needs – scaling in, scaling out and scaling up



```

No one, predefined approach fits everyone, so we need to be able to scale our use of Use-Case 3 .0 in several

different dimensions:

```

1\. Use cases scale in to provide more guidance to less experienced practitioners (developers,

&#x20;   analysts, testers, etc.) or to practitioners who want or need more guidance.

2\. They scale out to cover the lifecycle, covering not only requirements, design, coding and test

&#x20;   but also operational usage and maintenance.

3\. They scale up to support large and very large systems such as systems of systems: enterprise

&#x20;   systems, product lines, and layered systems. Such systems are complex and are typically

&#x20;   developed by many teams working in parallel, at different sites, possibly for different

&#x20;   companies, and reusing many legacy systems or packaged solutions.



```

Regardless of the complexity of the system you are developing you always start in the same way by identifying

the most important use cases and creating a big picture summarizing what needs to be built. You can then

adapt Use-Case 3 .0 to meet the emerging needs of the team. In fact, Use-Case 3 .0 insists that you continuously

inspect and adapt its usage to eliminate waste, increase throughput and keep pace with the ever-changing

demands of the team.

```



USE-CASE 3 .0 The Guide to Succeeding with Use Cases

Page 70



\## Conclusion



```

Use-Case 3 .0 exists as a set of proven and well-defined practices that are compatible with many other

software development practices such as Continuous Integration, Intentional Architecture, and Test-Driven

Development. It also works with all popular management practices. In particular, it has the lightness and

flexibility to support teams that work in an agile fashion. It also has the completeness and rigor required to

support teams that are required to work in a more formal or waterfall environment.

```

```

Use-Case 3 .0 is:

```

\- \*\*lightweight\*\* – in both its definition and application.

\- \*\*scalable\*\* – and suitable for teams and systems of all sizes.

\- \*\*adaptable\*\* – and suitable for all types of systems and development approaches

\- \*\*easy to use\*\* – use-case models can be quickly put in place and the slices created to meet the

&#x20;   teams’ needs.



```

Use-Case 3.0 is 100% compatible with teams that are already using user stories.

```

```

Use-Case 3 .0 is free and offered to the public in this guide and as a set of supporting Essence Practices

available from http://www.ivarjacobson. com. This is offered as a stand-alone set of cards or as part of the Essence

Workbench environment.

```

```

This is the first of many publications on Use-Case 3 .0, you can expect to see many other articles, white papers

and blogs on the subject published on http://www.ivarjacobson.com

```



USE-CASE 3.0 The Guide to Succeeding with Use Cases

Page 71



\## Appendix 1: Relationship between Use-Case 3.0 practices



```

We have used the Essence language to define and describe all Use-Case 3.0 practices. FIGURE 45 below shows

how each practice is related to other practices in Use-Case 3.0. Each dashed arrow on the figure denotes an

Extension^1.

```

```

All Use-Case 3.0 practices are an extension from the Use-Case 3.0 Foundation practice: i.e. all these practices

inherit the concepts and principles defined inside the Use-Case 3.0 Foundation, and they also inherit a

common definition of an Essence Alpha for “Use Case”, and an Essence Alpha for “Use-Case Slice”.

```

```

The Use-Case 3.0 Foundation does not define any activities (i.e. things to do); it has been created as a

separate practice simply to limit the number of concepts and elements that need to be defined in other Use-

Case 3.0 practices.

```

```

FIGURE 45 : THE USE-CASE 3.0 PRACTICE FAMILY

```

```

Please note that the extension relationships (denoted by dashed arrows in the figure) in the Use Case 3.0

practice family do NOT limit how these practices may be composed together. Any practice can be composed

(i.e. used together) with any combination of the other Use-Case 3.0 practices, if it is useful to do so.

```

(^1) “Extension refers to the modification or customization of an element to suit a new context. For example, a Work Product

defined in practice P1 may be modified in the context of a wider practice P2 that uses P1 as a component. The extension

mechanism in Essence allows elements to be modified or customized, and has two key features:

1\) Extension is “aspectual” in the sense that the element being modified is oblivious of the modification.

2\) Extension is non-destructive, in the sense that the original element still exists and is available.”

(From Essence – Kernel and Language for Software Engineering Methods Version 1.2).





USE-CASE 3.0 The Guide to Succeeding with Use Cases

Page 72



```

For example:

```

```

● Use-Case Light Modeling can be composed together with Use-Case Storytelling – indeed we

would expect this composition to be the default choice used by use-case practitioners.

● Use-Case Authoring is an extension of Use-Case Storytelling. This means that a use-case

practitioner may first apply the Use-Case Storytelling practice in their work to describe a use

case. If the use-case practitioner later decides that more structure and detail is required in the

use case, they may then apply the Use-Case Authoring practice - without having to discard or

significantly rework any work products previously created when using the Use-Case Storytelling

practice. The use-case narrative and supporting information work products are both extended to

add more levels of detail.

```



USE-CASE 3.0 The Guide to Succeeding with Use Cases

Page 73



\## Appendix 2: Work Products



```

This appendix provides definitions and further information of the work products used by Use-Case 3 .0. The

work products covered are:

```

\- Supporting Information

\- Test Case

\- Use-Case Model

\- Use-Case Narrative





USE-CASE 3.0 The Guide to Succeeding with Use Cases

Page 74



\*\*Supporting Information\*\*



```

The purpose of the supporting information is to capture important terms used to describe the system, and

any and all requirements that don’t fit inside the use-case model.

```

```

The supporting information:

```

\- Helps ensure a common understanding of the specified solution.

\- Focuses on concepts and terms that need to be understood by everyone involved in the work, and

&#x20;   in particular those terms referenced by the use cases.

\- Captures those important global requirements and quality attributes that don’t relate to any

&#x20;   single use case such as supported platforms and system availability.

\- Details any standards that need to be followed. For example, coding, presentation, language,

&#x20;   safety, and any other industry standards that apply to the system.

\- Helps to identify additional work items not readily identifiable directly from the use-cases, such

&#x20;   as those that will be used to demonstrate the different platforms supported or the desired levels

&#x20;   of availability.

The role of the supporting information is to support the evolution of the use cases and the implementation of

the use-case slices. Capture it to complement your use-case model and avoid miscommunication between the

team members. The information can come from many sources, such as other requirements documents,

specifications, and discussions with stakeholders and domain experts. You can also include domain, process,

and other business models if they are a useful aid to understanding the use-case model and the system it

describes.



```

The supporting information can be documented at varying levels of detail ranging from a simple set of basic

definitions through to a comprehensive and fully described set of definitions, standards, and quality

attributes. The supporting information can be presented at the following levels of detail:

```

```

Notes Taken: A basic level of detail that indicates what is included is just an outline of the most obvious

terms and areas to be addressed.

```

```

More detail will need to be added if the information is to support the successful identification and

preparation of the use-case slices.

```

```

Simply Defined: All terms referenced by the use-case narratives must be defined and the system’s global quality

attributes clearly specified. At this level of detail these are captured as simple lists of declarative

statements such as those used in the glossary that accompanies this e-book.

```

```

This is the lightest level of detail which provides support for the development of the use-case slices.

It also clarifies the global requirements of the system, enabling the team to tell if the system

implementing the slices is truly usable and not just demonstrable. It is suitable for most teams,

particularly those that collaborate closely with their users and are able to fill in any missing detail by

talking with them.

```

```

Modeled and Illustrated: More detail can be added to the supporting information by transforming the basic

definitions into models that precisely capture the definitions, their attributes and their relationships,

and providing real world examples to clarify things. At this level of detail, we go beyond simple definitions

and start to use complementary techniques such as business rule catalogues, information modeling and

domain modeling. It is particularly useful for supporting those use-case models where a

misunderstanding of the requirements could have severe safety, financial or legal consequences.

```



USE-CASE 3.0 The Guide to Succeeding with Use Cases

Page 75



```

Comprehensively Defined: Sometimes it is necessary to clarify the information by providing more detailed

explanations and support materials such as comprehensive examples, derivations and cross- references.

```

```

At this level of detail, the supporting information becomes more complicated, with more precision,

cross-referencing and use of formal specification techniques.

```

```

The supporting information provides a central location to look for terms and abbreviations that may be new

to the team and to find the global quality attributes that everyone in the team should understand. It is a

valuable complement to the use-case model itself. Without the supporting information it can be difficult to

understand what it means for the system to be usable and ready for use.

```

```

The supporting information is usually represented as a simple list of terms and their definitions. The list is often split

up into sections such as definitions of terms, business rules, operational constraints, design constraints,

standards, and system-wide requirements. The list may be published as part of a Wiki site to simplify access

and maintenance.

```



USE-CASE 3.0 The Guide to Succeeding with Use Cases

Page 76



\*\*Test Case\*\*



```

The purpose of a test case is to provide a clear definition of what it means to complete a slice of the

requirements. A test case defines a set of test inputs and expected results for the purpose of evaluating

whether or not a system works correctly.

```

```

Test cases:

```

\- Provide the building blocks for designing and implementing tests.

\- Provide a mechanism to complete and verify the requirements.

\- Allow tests to be specified before implementation starts.

\- Provide a way to assess system quality.

Test cases are an important, but often neglected, part of a use case. The test cases provide the true definition

of what it is that the system is supposed to do to support a use case. The test cases are particularly important

when we start to slice up the use cases as they provide the developers with a clear definition of what it means

to successfully implement a use-case slice.



```

Test cases can be used with many forms of requirements practice including use cases, user stories and

declarative requirements. In all cases the tester must be presented with a slice of requirements to test, one

with a clear beginning and end from which they can derive an executable test scenario.

```

```

Test cases can be presented at the following levels of details:

```

```

Test Ideas Formulated: The lightest level of detail just captures the initial idea that will inform the test

case. When defining a test case, it needs to be clear what the idea behind the test case is and what it is

that it is verifying.

```

```

More detail will need to be added if the test case is to be executable.

```

```

Scenario Chosen: To be able to run a test case a tester must be presented with a test scenario to execute. The

structure of the use-case narrative ensures that every use-case slice will present the tester with one

or more candidate test scenarios. The art of creating effective test cases is to choose the right subset

of the potential test scenarios to fulfill the test idea and clearly define done for the slice.

```

```

This is the lightest level of detail that provides an executable test case. Once the test scenario has been

chosen the test case is defined enough to support exploratory and investigative testing. This can be

very useful early in the project lifecycle when the insight provided by testing the system is invaluable,

but the specification (and solution) may not be stable enough to support formal, scripted testing.

```

```

Variables Identified: A test case takes some inputs, manipulates system states, and produces some results.

These variables appear as inputs, internal states, and outputs in the requirements. At this level of

detail, the acceptable ranges for the key variables involved in the scenario are explicitly identified.

```

```

This level of detail is suitable for those test cases where soliciting the opinion of the tester is an

essential part of the test, for example when undertaking usability testing. It can also be used when more

structure is needed for exploratory and investigative testing.

```



USE-CASE 3.0 The Guide to Succeeding with Use Cases

Page 77



```

Variables Set: The test case can be further elaborated by explicitly providing specific values for all the

variables involved in the test case.

```

```

This level of detail is suitable for manual test cases, as all the information needed by an intelligent

tester to repeatedly and consistently execute the test case is in place.

```

```

Scripted / Automated: If a test case is to be used many times or to support many different tests then it is

worth making the effort to fully script or automate it.

```

```

At this level of detail, the test case can be executed without any intervention or additional decision

making.

```

```

The test cases are the most important work product associated with a use case; remember it is the test cases

that define what it means to complete the development of a use case, not the use-case narrative. In a way

the test cases are the best form of requirements you can have.

```

```

The test cases will be used throughout the lifetime of the system – they are not just used during the

implementation of the use cases but are also used as the basis for regression testing and other quality checks.

The good news is that the structure of the use cases and use-case narratives naturally leads to well-formed,

robust, and resilient test cases; ones that will last as long as the system continues to support the use cases.

```

```

The use-case narratives are collections of flows that the system must support, and for the basic scenario and

for each extension described in the use-case narrative there will have to be at least one test case. You create

the test cases at the same time as the use-case narratives as part of preparing a use-case slice for

development.

```



USE-CASE 3.0 The Guide to Succeeding with Use Cases

Page 78



\*\*Use-Case Model\*\*



```

A use-case model is a model of all of the useful ways to use a system, and the value that they will provide.

The purpose of a use-case model is to capture all the useful ways to use a system in an accessible format that

captures a system’s requirements and can be used to drive its development and testing.

```

```

A use-case model:

```

\- Allows teams to agree on the required functionality and characteristics of a system.

\- Clearly establishes the boundary and scope of the system by providing a complete picture of its

&#x20;   actors (being outside the system) and use cases (being inside the system).

\- Enables agile requirements management.



```

A use-case model is primarily made up of a set of actors and use cases, and diagrams illustrating their

relationships. Use-case models can be captured in many different ways including as part of a Wiki, on a white

board or flipchart, as a set of PowerPoint slides, in a MS Word document, or in a modeling tool.

```

```

The use-case model can be prepared at different levels of detail:

```

```

Value Established: The first step towards a complete use-case model is to identify the most important

actors and use cases – the primary ones. These are the ones that provide the value of the system.

```

```

This is the lightest level of detail. It is suitable for most projects, particularly those adding new

functionality to existing systems where there is little or no value in modeling all the things the system

already does.

```

```

System Boundary Established: The primary actors and use cases capture the essence of why the system is

built. They show how the users will get value from the system. They may not provide enough value to set

it up and keep it running. In these cases, supporting actors and operational use cases are necessary to enable and

support the effective operation of the system.

```

```

This level of detail is useful when modeling brand new systems or new generations of existing systems.

At this level of detail all the systems actors and use cases are identified and modeled.

```

```

Structured: The use-case model often contains redundant information, such as common sequences or

patterns of interaction. Structuring the use-case model is the way to deal with these redundancies.

```

```

For large and complex systems, especially those that are used to provide similar functionality within many

different contexts, structuring the use-case model can aid understanding, eliminate waste, and help

you find reusable elements.

```

```

As long as your use-case model clearly shows the value that the stakeholders will receive from your new or

updated system then it is doing its job. Care should be taken when adding detail to the model. Only advance

to System Boundary Established or Structured if these levels of detail are clearly going to add value and help

you deliver the new system more efficiently.

```



USE-CASE 3.0 The Guide to Succeeding with Use Cases

Page 79



\*\*Use-Case Narrative\*\*



```

The purpose of a use-case narrative is to tell the story of how the system and its actors work together to

achieve a particular goal.

```

```

Use-case narratives:

```

\- Explore the requirements and identify the use-case slices

\- Describe a sequence of actions, including variants that a system and its actors can perform to

&#x20;   achieve a goal.

\- Are presented as a set of scenarios that describe how an actor uses a system to achieve a goal,

&#x20;   and what the system does for the actor to help achieve that goal.

\- Capture the requirements information needed to support the other development activities.

Use-case narratives can be captured in many ways including as part of a Wiki, on index cards, as MS Word

documents, or inside one of the many commercially available work management, requirements management or

modeling tools.



```

Use-case narratives can be developed at different levels of detail ranging from a bulleted outline, identifying

the basic scenario and the most important extensions, through to a comprehensive, highly detailed specification

that defines all the actions, inputs and outputs involved in performing the use case. Use-Case narratives can

be prepared at the following levels of detail:

```

```

Briefly Described: The lightest level of detail that just captures the goal of the use case and which actor

starts it.

```

```

This level of detail is suitable for those use cases you decide not to implement. More detail will be

needed if the use case is to be sliced up for implementation.

```

```

Bulleted Outline: The use case must be outlined in order to understand its size and complexity. This level of

detail also enables effective scope management as the outline allows the different parts of the use

case to be prioritized against one another and, if necessary, targeted onto different releases.

```

```

This is the lightest level of detail that enables the use case to be sliced up and development to progress. It is

suitable for those teams that are in close collaboration with their users and are able to fill in any

missing detail via conversations and the completion of the accompanying test cases. Capture a bulleted list

of the steps in the basic scenario and names of extensions. Or for more detail, capture the steps of each

extension, when it diverts from the basic scenario, and where it returns to the basic scenario - if relevant).

Capture any Constraints (pre-conditions, post-conditions or special requirements) that apply to the whole

use case

```

```

Essential Outline: Sometimes it is necessary to clarify the responsibilities of the system and its actors

whilst undertaking the use case. A bulleted outline captures their responsibilities but does not clearly

define which parts of the use case are undertaken by the system and which are undertaken by the

actor(s).

```

```

At this level of detail, the narrative becomes a description of the dialog between the system and its

actors. It is particularly useful when establishing the architecture of a new system or trying to establish

a new user experience.

```

```

Fully Described: Use-case narratives can be used to provide a highly detailed requirements specification by

evolving them to their most comprehensive level of detail, fully described. The extra detail may be

needed to cover for the absence of expertise within the team, a lack of access to the stakeholders or

to effectively communicate complex requirements.

```



USE-CASE 3.0 The Guide to Succeeding with Use Cases

Page 80



```

This level of detail is particularly useful for those use cases where a misunderstanding of the contents

could have severe safety, financial or legal consequences. It can also be useful when off-shoring or

out- sourcing software development.

```

```

The use-case narrative is a very flexible work product that can be expanded to capture the amount of detail

you need to be successful whatever your circumstances. If you are part of a small team working collaboratively

with the customer on an exploratory project then bulleted outlines will provide a very lightweight way of

discovering the requirements. If you are working in a more rigid environment where there is little access to

the real experts, then essential outlines or fully described narratives can be used to plug the gaps in the

team’s knowledge.

```

```

Not every use-case narrative needs to be taken to the same level of detail – it is not uncommon for the most

important and risky use cases to be more detailed than the others. The same goes for the sections of the use-

case narrative – the most important, complex, or risky parts of a use case are often described in more detail

than the others.

```



USE-CASE 3.0 The Guide to Succeeding with Use Cases

Page 81



\## Glossary of Terms



```

Actor: An actor defines a role that a user can play when interacting with the system. A user can either be an

in- dividual or another system. Actors have a name and a brief description, and they are associated to the use

cases with which they interact.

Application: Computer software designed to help the actors in performing specific tasks.

Aspect-Oriented Programming: A programming technique that which aims to increase modularity by allowing

the separation of cross-cutting concerns (see http://en.wikipedia.org/wiki/Aspect-oriented\_programming).

Basic Scenario: The description of the normal, expected execution path through the use case. This is the

path taken by most of the users most of the time; it is the most important part of the use-case narrative. Also

called the basic flow.

Customer: The stakeholder who is paying for the development of the system or who is expected to purchase

the system once it is complete.

Extension: Description of variant or optional behavior as part of a use-case narrative. Also called an alternate

flow. Extensions are defined relative to the use case’s basic scenario – and describe a full path through the

use case.

Requirements: What the system must do to satisfy the stakeholders.

Scenario : A complete sequence of steps through the whole use case. This is described as a simple sequence

of steps, each of which involves the system and / or one of the actors doing something.

Separation of Concerns: The process of splitting up a system to minimize the overlap in functionality (see

http://en.wikipedia.org/wiki/Separation\_of\_concerns).

Software System: A system made up of software, hardware, and digital information, and that provides its

primary value by the execution of the software.

A software system can be part of a larger software, hardware, business or social solution.

Stakeholder: A person, group or organization who affects or is affected by the system. Stakeholders can

include the user, the customer, the builder, the team, an administrator, and others.

System: A group of things or parts working together or connected in some way to form a whole. Typically

used to refer to the subject of the use-case model: the product to be built.

System Element: Member of a set of elements that constitutes a system (ISO/IEC 15288:2008)

Team: a term used in this ebook to identify the group of people who implement the system. A team will

normally include people who develop the system and people who test the system. The team may also include

a user representative - who ensures the work done by the team is also valuable to the stakeholders.

Test Case: A test case defines a set of test inputs and expected results for the purpose of evaluating whether

or not a system works correctly.

Use Case: A use case is all the ways of using a system to achieve a particular goal for a particular user.

Use-Case 3 .0: A scalable set of agile practices that use use-cases to capture a set of requirements and drive

the incremental development of a system to fulfill them.

Use-Case Diagram: A diagram showing a number of actors and use cases, and their relationships.

Use-Case Model: A model of all of the useful ways to use a system, and the value that it will provide. A use-

case model is primarily made up of a set of actors and a set of use cases, and diagrams illustrating their

relationships.

Use-Case Narrative: A description of a use case that tells the story of how the system and its actors work

together to achieve a particular goal. It includes a sequence of actions (including variants) that a system and

its actors can perform to achieve a goal.

Use-Case Slice: A slice of a use case that provides clear value to the development stakeholders. It includes a

requirements slice specifying the interaction with its actor(s) and the actions taken by the use case, and a test slice

verifying the requirements. Use-case slices are used to stage the delivery of the use case.

User: A stakeholder who interacts with the system to achieve their goals.

User Story: A short, simple description of something a user wants to do with the system, told from the

perspective of the person who desires the new capability, usually a user or customer of the system.

```



USE-CASE 3.0 The Guide to Succeeding with Use Cases

© 2005 - 2024 Ivar Jacobson International SA. All rights reserved. Page^82



\## Acknowledgements



\*\*General\*\*



```

Use-Case 3 .0 is based on industry-accepted best practices, used and proven for decades. We would like to

thank the tens of thousands of people who use use cases every day on their projects and in particular those

who share their experiences inside and outside their own organizations. Without all of their hard work and

enthusiasm we wouldn’t have the motivation or knowledge to attempt this evolution of the technique. We

hope you find this e-book useful, and continue to inspect and adapt the way that you apply use cases.

```

\*\*People\*\*



```

We would also like to thank everyone who has directly contributed to the creation of this or previous versions

of this e-book including, in no particular order, Kurt Bittner, Paul MacMahon, Richard Schaff, Eric lopes

Cardozo, Svante Lidman, Craig Lucia, Tony Ludwig, Ron Garton, Burkhard Perkens-Golomb, Arran Hartgroves,

James Gamble, Brian Hooper, Stefan Bylund, and Pan-Wei Ng.

```



USE-CASE 3.0 The Guide to Succeeding with Use Cases

© 2005 - 2024 Ivar Jacobson International SA. All rights reserved. Page^83



\*\*Bibliography\*\*



```

Object-oriented software development in an industrial environment Ivar Jacobson

The first published paper to describe Use Cases.

```

```

● Publisher: In Conference Proceedings of Object-oriented Programming Systems, Languages, and

Applications - OOPSLA 87 (1987)

Object-Oriented Software engineering: A Use Case Driven Approach Ivar Jacobson, Magnus Christerson,

Patrik Jonsson, Gunnar Overgaard. The original book that introduced use cases to the world.

```

```

● Publisher: Addison-Wesley Professional; revised edition (July 10, 1992)

● ISBN-10: 0201544350 ISBN-13: 978- 0201544350

The Object Advantage: Business Process Reengineering With Object Technology Ivar Jacobson, Maria

Ericsson, Agneta Jacobson

The definitive guide to using use cases for business process reengineering.

```

```

● Publisher: Addison-Wesley Professional (September 30, 1994)

● ISBN-10: 0201422891 ISBN-13: 978- 0201422894

Software Reuse: Architecture, Process and organization for Business Success Ivar Jacobson, Martin

Griss, Patrik Jonsson

A comprehensive guide to software reuse, including in-depth guidance on using use cases for the development

of product lines and systems-of-interconnected systems.

● Publisher: Addison-Wesley Professional (June 1, 1997)

● ISBN-10: 0201924765 ISBN-13: 978- 0201924763

Use-Case Modeling

Kurt Bittner and Ian Spence

A guide to creating use-case models and writing use cases.

```

```

● Publisher: Addison-Wesley Professional; 1 edition (August 30, 2002)

● ISBN-10: 0201709139 ISBN-13: 978- 0201709131

Aspect-oriented Software Development with Use Cases Ivar Jacobson and Pan-Wei Ng

The book that introduced the world to use-case slices.

```

```

● Publisher: Addison-Wesley Professional; 1 edition (January 9, 2005)

● ISBN-10: 0321268881 ISBN-13: 978- 0321268884

Use Cases are Essential Ivar Jacobson and Alistair Cockburn

The co-authored paper that launched a new wave of interest in Use Cases

```

```

● ACM Queue November 11, 2023. Volume 21, issue 5.

Use Cases Foundation Ivar Jacobson and Alistair Cockburn

A concise paper published in 2024 which defines the common ground that lies between the two most widely

practiced ways of working with use cases. Version 1.1

```

```

Unifying User Stories, Use Cases, Story Maps: The power or verbs Alistair Cockburn

Alistair Cockburn’s new guide to what makes use cases, user stories and story maps all work, and what makes

them work well together.

```

```

● Publisher: Humans and Technology Press; 1 edition (May 2024)

● ISBN 978- 1 - 7375197 - 6 - 8

```



USE-CASE 3.0 The Guide to Succeeding with Use Cases

© 2005 - 2024 Ivar Jacobson International SA. All rights reserved. Page^84



```

Essence – Kernel and Language for Software Engineering Methods – Version 1.2

```

```

The standard that defines the elements and language notation used to describe the Essence kernel Alphas and

any practice or method using the Essence language.

```

```

● Object Management Group

● https://www.omg.org/spec/Essence/

```



USE-CASE 3.0 The Guide to Succeeding with Use Cases

© 2005 - 2024 Ivar Jacobson International SA. All rights reserved. Page^85



\*\*About the Authors\*\*



\*\*Ivar Jacobson\*\*



```

Dr. Ivar Jacobson is a father of components and component architecture, use cases, aspect-oriented software

development, modern business engineering, the Unified Modeling Language and the Rational Unified Process.

His latest contribution to the software industry is a formal practice concept that promotes practices as the

‘first-class citizens’ of software development and views process simply as a composition of practices. He is

the principal author of six influential and best-selling books. He is a keynote speaker at many large

conferences around the world and has trained several process improvement consultants.

```

\*\*Ian Spence\*\*



```

As Chief Technology officer at Ivar Jacobson International, Ian Spence specialized in the agile application of

the Unified Process. He is a certified RUP practitioner, ScrumMaster, SAFe Fellow and an experience coach

having worked with 100s of projects to introduce iterative and agile techniques. He has over 30 years

experience in the software industry, covering the complete development lifecycle, including requirements

capture, architecture, analysis, design, implementation and project management. His specialty subjects are

iterative project management, agile team working and requirements management with use cases. In his role

as CTO, Ian contributed to the technical direction of Ivar Jacobson International and he continues to work

with the company’s Technology office to define the next generation of smart, active, software development

practices. He was the project lead and process architect for the development of the Essential Unified Process

and the practices it contains. When he is not working on researching, capturing and defining practices he

spends his time assisting companies in the creation and execution of change programs to improve their

software development capability. He is co-author of the Addison Wesley books “Use Case Modeling” and

“Managing Iterative Software Development Projects”.

```

\*\*Keith de Mendonca\*\*



```

Dr. Keith de Mendonca is a principal consultant at Ivar Jacobson International. As a Chief Technology Architect

and Chief Site Technologist at Symbian Ltd, he worked with software engineers in the UK, India and China to

develop an operating system for the first wave of smartphones – used by Nokia, Sony Ericsson, Fujitsu and

many other phone manufacturers. He returned to the UK to join Ivar Jacobson International in 2 015. Keith

has helped many medium-sized and large enterprises increase productivity and become more innovative by

adopting lean-agile development practices at the team and at the enterprise level.

```



USE-CASE 3.0 The Guide to Succeeding with Use Cases

© 2005 - 2024 Ivar Jacobson International SA. All rights reserved. Page^86



```

About Ivar Jacobson International

IJI is a global services company specializing in improving the

performance of software development teams by removing

barriers to the adoption of new practices. Through the provision

of high caliber people, innovative practices, and proven

solutions, we ensure that our customers achieve strong

business/IT alignment, high per- forming teams, and projects

that deliver.

```

```

http://www.ivarjacobson.com

```

```

Switzerland

+41 (0) 79 330 16 57

```

```

United Kingdom

+44 (0) 20 3934 0278

```

```

Sweden

+46 (0) 8 515 10 174

```





