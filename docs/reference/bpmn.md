## BPMN

## Made

## Easy

## With

# PROCESS-BILITY

## Kevin

## Tan

2025May

## From Complexity to Clarity -

## Effective Visual Communication in

## Digital Transformation


**BPMN Made Easy with Process-bility**
Effective Visual Communication for Digital Transformation
© 2025 **Kevin Tan**
All rights reserved.
**Published by Process-bility Press**
[http://www.process-bility.com](http://www.process-bility.com)
**ISBN:** 978-1-7638978-0-
No part of this book may be reproduced, stored in a retrieval system, or transmitted in any form or by
any means—electronic, mechanical, photocopying, recording, or otherwise—without prior written
permission from the publisher, except in the case of brief quotations for review purposes.
This book is designed to provide accurate and authoritative information regarding the subject matter.
It is sold with the understanding that the publisher is not engaged in rendering legal, business, or other
professional services. If expert assistance is required, the services of a competent professional should
be sought.


With over 20 years of global experience, working for major companies like
Siemens and SAP in 7 countries, I’ve had the privilege of solving some of
the most complex business challenges by aligning People, Process,
Applications, and Data. Throughout my career as a former CIO, CFO, Head
of Operational Excellence, and Head of Service Business, I’ve seen first-
hand how important process modeling is in every business stage, from
start-ups to acquisitions.
In the world of process modeling, complexity often overshadows clarity,
leaving many professionals—both beginners and experts—struggling to
communicate their ideas effectively. That’s where Kevin Tan steps in, with
an unwavering passion to demystify the art of Business Process Model
and Notation (BPMN). Through his years of experience and dedication,
Kevin has developed a fresh approach that blends simplicity, storytelling,
and visual balance, making process modeling accessible to everyone.
As I turned the pages of BPMN Made Easy with Process-bility, I found
myself not just reading but discovering. Kevin’s insights opened my eyes
to the nuances of process modeling in a way I had never imagined. What
initially seemed like a straightforward guide quickly became an ocean of
value waiting to be unlocked. Every chapter revealed new dimensions of
BPMN, and I came to realise just how much potential was hidden beneath
the surface of what I once thought was a rigid, complex framework.

##### Foreword

```
ii
```

The more I delved into the principles of Storytelling and Visual Balance,
the more I appreciated the depth and power of Kevin’s approach. His
ability to break down complicated concepts into digestible, actionable
steps made it clear that BPMN is not just a tool for experts, but a language
anyone can master. And as I continued to explore the pages, I felt
confident that I was gaining skills that could drive real transformation in
how processes are modeled, understood, and communicated.
This book, BPMN Made Easy with Process-bility, is more than a guide; it’s
an invitation to explore a new way of thinking about processes. Whether
you’re just starting out or are a seasoned analyst, Kevin’s insights will
resonate with you. His desire to share his expertise and help others
overcome the challenges of process modeling is evident on every page.
Kevin’s belief that process models should not only function but also
inspire collaboration and innovation is at the heart of this work.
Dive in, and you’ll find that this book is not just for experts but for anyone
who wants to unlock the true potential of BPMN. With Kevin as your guide,
complexity gives way to clarity, and the art of process
modeling becomes an empowering tool for everyone.
**Gia Thi Nguyen**
VP, SAP Signavio, Market Impact APJ & GC
Singapore, Oct 2024
iii


In the world of business process modeling, it’s easy to get lost in complex
notations, gateways, and jargon. For years, I saw professionals—new and
experienced—struggle to create models that worked and could be easily
understood across an organisation. That struggle inspired the creation of
**Process-bility**.
Born from two decades of hands-on experience, Process-bility makes BPMN
easier, clearer, and more intuitive—without losing its power. It focuses on
three core principles: Storytelling, Visual Balance, and Simplicity, ensuring
models not only function but also tell engaging stories that everyone—from
CEOs to frontline employees—can follow.
Along the way, I learned that process modeling isn’t just about technical
accuracy—it’s about clarity, growth, and collaboration. When models are
easy to understand, they spark conversations, align teams, and encourage
continuous improvement.
This book isn’t just about building better models—it’s about communicating
better, working together, and enjoying the process. Whether you're a
seasoned business analyst or just starting your journey, I hope Process-bility
provides the tools, insights, and confidence to unlock your potential. Let’s
turn complexity into clarity and make BPMN easy with Process-bility.
**Kevin Tan
[http://www.Process-bility.com](http://www.Process-bility.com)**

##### Preface

```
iv
```

v
**CONTENTS
Chapter 1 Introduction
Chapter 2 The Foundations of BPMN
Chapter 3 BPMN Gateways
Chapter 4 Visual Balance with Process-bility
Chapter 5 Visual Balance in Action
Chapter 6 Simplicity in Process-bility
Chapter 7 Simplicity in Action
Chapter 8 Storytelling with Process-bility
Chapter 9 Storytelling in Action
Chapter 10 Correlating Agile User Stories with BPMN Models
Chapter 11 Process-bility for Digital Transformation
Chapter 12 Real-World Business Scenarios Modelling Challenges
Chapter 13 Process Architecture Case Study**


```
From Complexity to Clarity
Why This Book?
The Problem with BPMN
What You’ll Learn
Why Process-bility Matters?
Closing Thoughts
```
### Introduction

##### Chapter 1


Have you ever tried to navigate the world of Business Process Model and
Notation (BPMN), only to find yourself tangled in its complexities? The notations,
Gateways, Flow Lines—it can all feel overwhelming, even for seasoned
professionals. But BPMN is critical. In today’s fast-paced, digital-first world, the
ability to model and truly understand your business processes is key to successful
digital transformation and continuous improvement.
Process-bility strips away the complexity from BPMN, replacing it with clarity,
simplicity, and storytelling. At its core, process modeling is more than just
diagrams and symbols—it’s about telling a story. A visual story about your
organisation, your people, and how they collaborate to achieve meaningful
business outcomes.

###### From Complexity to Clarity


###### Why This Book?

With over three decades of experience in business process modeling, I’ve
encountered it all—the good, the bad, and the unnecessarily complex. Through
these experiences, I developed a set of principles called Process-bility. This
methodology breaks down BPMN into its most essential components, focusing on
three core principles:
**Visual Balance** :
A well-designed BPMN model should be visually balanced. That means no messy
cross-over lines, no cluttered activities, and an easy-to-follow flow from start to
finish. A visually balanced model is not just more aesthetically pleasing—it’s
easier to understand, which leads to better decisions.
**Simplicity** :
BPMN can quickly get bogged down in details and notations that add more
complexity than value. The best BPMN models are simple but not simpler. They
contain just enough information to convey the process clearly, without
overwhelming the reader.
**Storytelling:**
At its core, every BPMN model should tell a story that anyone—from a CEO to an
entry-level analyst—can understand. The focus is not on showing off how many
notations you know, but on creating a clear, engaging narrative that
communicates the process effectively.

## 1

## 2

## 3


```
BPMN is undoubtedly a powerful notation standard, capable of supporting both
events and activities, as well as business rules and decision flows. However, its
very strength can also be its downfall. With hundred of notations to choose from,
and no established best practices, many process modelers fall into the trap of
focusing too heavily on technical complexity. Often, models are driven by the
need to represent every detail, rather than focusing on business clarity.
This technical bias leads to over-complicated models where many business rules
and decision flows are treated as processes themselves. The result is a model
that, while technically accurate, is confusing and overwhelming for all
stakeholders. Instead of providing clarity, these models muddy the waters by
including unnecessary detail, making it harder for teams to understand the
processes.
When process modelers attempt to represent every nuance, decision, and rule in
a BPMN diagram, they often lose sight of the bigger picture. Without a clear
framework, it becomes easy to overcomplicate the model. The true purpose of
BPMN—capturing and communicating a clear, digestible narrative of how a
business operates—gets lost in the details.
Process-bility offers a superior approach. By focusing on Visual Balance, Simplicity
and Storytelling, it ensures that BPMN models serve their real purpose:
communicating not just how a process works, but why it matters to the business.
```
###### The Problem with BPMN


In this book, you’ll learn how to approach BPMN with the same mindset I
developed through years of trial and error. You’ll discover how to:
Use Visual Balance to create BPMN models that are easy to read and
understand.
Tell a story with clarity using BPMN models - with minimum notations.
Apply the principles of Storytelling to cut through the noise and deliver BPMN
models that drive real, actionable insights.
We’ll also look at common BPMN mistakes and how to avoid them, share real-
world examples of BPMN models done right (and wrong), and give you practical
tips on applying Process-bility in your day-to-day BPMN modeling.
Whether you’re new to BPMN or a seasoned professional, this book will show you
how to take your BPMN process modeling to the next level.

###### What You’ll Learn

```
Absorb what is useful,
discard what is not,
add what is
specifically your own.
BRUCE LEE
```

The business landscape is changing at an unprecedented pace. Digital
transformation and continuous improvement are no longer a buzzword—it’s a
necessity for survival. And as businesses pivot toward automation, artificial
intelligence, and data-driven decision-making, having a clear understanding of
your processes becomes even more critical.
Process-bility helps you see the bigger picture. It’s not just about creating a
diagram that looks good—it’s about fostering collaboration, breaking down silos,
and driving meaningful change within your organization.
As we dive into the world of BPMN through the lens of Process-bility, you’ll see
how a well-modeled process can unlock new efficiencies, improve
communication, and ultimately, help your business thrive.

###### Why Process-bility Matters?

```
with
Fg1.1 The future is now
```

Process is the manifestation of activities when knowledge is applied to achieve a
desired business outcome. Think of BPMN as the X-ray of your business
processes. Just like an X-ray helps doctors diagnose a problem, a well-modeled
process helps you diagnose inefficiencies, identify opportunities, and ensure that
your business is operating at its full potential.
So let’s get started on this journey together—from complexity to clarity, from
confusion to understanding. BPMN made easy with Process-bility.

###### Closing Thoughts

##### Process is the manifestation of

##### activities when knowledge is applied

##### to achieve a desired business

##### outcome.


```
What is BPMN?
The Key Elements of BPMN
Why Most People Get It Wrong?
Get Ready With Process-bility
Closing Thoughts
```
### The foundation of BPMN

##### Chapter 2


###### What is BPMN?

Business Process Model and Notation (BPMN) is an international standard
developed to visually represent business processes in a way that can be easily
understood across various roles—from stakeholders to developers. Initially
introduced by the Business Process Management Initiative (BPMI) in 2004, it was
later adopted by the Object Management Group (OMG) in 2005. The goal was to
bridge the gap between business and IT by providing a universal language for
process modeling, and BPMN quickly became the go-to standard. The release of
BPMN 2.0 brought enhancements, including expanded event and data flow
capabilities, making it even more robust for modern business process
management needs.
Fg2.1 BPMN 2.0 Notations


However, while BPMN 2.0 provides a rich, comprehensive framework, its official
OMG documentation is extremely technical, more like a programming manual
than a user-friendly guide. The dense, detail-oriented nature of the standard has
made it challenging for newcomers to approach. Consequently, many turn to
online resources to learn BPMN, often relying on tutorials or summaries that lack
depth and accuracy. This has led to widespread misinterpretations and
inconsistent practices, resulting in overcomplicated or ineffective models. Instead
of fostering clarity, **BPMN*** often ends up misunderstood and misused—its
intended simplicity lost in translation.
**BPMN*** specifically refers to Collaboration Diagrams within the BPMN 2.0 standard. While
BPMN 2.0 defines four types of diagrams—Process, Collaboration, Choreography, and
Conversation—our focus in this eBook is exclusively on Collaboration Diagrams, where
inter-team interactions and message flows are clearly visualised.
Fg2.2 Poor quality BPMN online resources to learn BPMN


###### The Key Elements of BPMN

At its core, BPMN revolves around five key elements:
**Event** , **Activity** , **Gateway** , **Swimlane** , and **Connecting Flow**.
These are the fundamental "building blocks" of process models, with each playing
a critical role in representing different aspects of a business process. The
remaining notations are essentially variations of these core elements, providing
additional detail or specificity, but they all function based on the same
foundational behaviors. By mastering these five key elements, you can navigate
BPMN without being overwhelmed by its many notations.
Fg2.3 BPMN Key Elements


**Event**
An Event represents something that occurs during a process. It can trigger the
start of an activity, mark its end, or serve as a checkpoint during the process.
Events are essential for understanding how the process flows and how it
responds to various triggers or changes.
Examples of Events include _Start Event_ , _Message Start Event_ , _End Event_ , and
_Intermediate Timer Event_ , among others.
Fg2.4 BPMN Notation - Events - Don’t worry, you only need to
understand less than 10 BPMN notations to be able to master
BPMN modelling
Start
Message
Start
End
Intermediate
Timer


**Activity**
An Activity represents tasks or work that is being performed. These can range
from manual tasks (like destroying duplicate hardcopies) to automated tasks (like
validating credit status). In BPMN, activities can be further categorised into _Tasks_ ,
_Sub-processes_ , and _Call Activities_ , but their core purpose remains the same—they
are the actions that move the process forward.
Fg2.5 BPMN Notation - Activity and Sub-Process


**Gateway**
Gateways control the flow of a process, acting as decision points where the flow
can either split into different paths or converge back into one. They ensure that
processes adapt to various scenarios, but they are often misunderstood and
overused.
The most commonly used Gateways are the _Exclusive Gateway_ and _Parallel
Gateway,_ while the _Inclusive Gateway_ and _Event-based Gateway_ are less frequently
used.
Fg2.6 BPMN Notation - Gateways - Don’t worry,
you only need to understand 4 Gateways to
model most of the processes.


**Swim Lane**
Swimlanes represent the roles, teams, or systems involved in the process. They
visually organise the process by assigning tasks to specific roles, making it easier
for stakeholders to understand their responsibilities and contributions within the
process.
Here are the variations
of Swimlane:
Pool
External Pool
Fg2.7 BPMN Notation - Swimlane, Pool and External Pool


**Connecting Flow**
Connecting Flows are the lines that link Activities, Gateways, Events and Artifacts.
They depict how the process transitions from one task to the next, ensuring that
the flow of the process remains clear and easy to follow.
Here are the variations of Connecting Flows:
Sequence Flow: Connects Activities, indicating the order of Activities in the
process.
Message Flow: Represents communication between different two Pools.
Association Flow: Links an object, such as an attachment or note, to an
Activity.
Fg2.8 BPMN Notation - Connecting Flow - Don’t worry, you only need to
understand 3 to be able to master BPMN modelling


###### Why Most People Get It Wrong?

Despite having a standardised notation, BPMN is often misused or
overcomplicated. Many people approach BPMN as a technical skill rather than a
storytelling tool, and that’s where the confusion starts.
Here are the most common mistakes:
**Overcomplicating the Model**
It’s tempting to include every possible detail in your BPMN model. You might want
to show every decision, exception, and path. But just because you can, doesn’t
mean you should. Overcomplicated models confuse the very people who need to
understand them—your stakeholders.
**Misuse of Gateways**
A significant issue in BPMN modeling is the lack of understanding of Gateways.
Many modelers misapply Gateways, resulting in confusion and misinterpretation
of the business scenarios and process flow.
Improper merging or branching of Gateways is another common mistake, often
disrupting the clarity of the model. Additionally, BPMN's flexibility sometimes
leads modelers to either overuse or underuse Gateways, further complicating the
diagram.
The key isn't just knowing how to place a gateway but understanding when and
why it's necessary to accurately depict process flows.


**Focusing on Notation, Not Communication**
Too often, BPMN modelers focus on getting the notation right without
considering whether the model actually communicates the process clearly. BPMN
is a visual language meant for communication, not a technical diagram reserved
for the elite few.
**Lack of understanding of Sequence Flow and Message Flow**
These two notations serve distinct purposes, and confusion between them
can significantly impact the accuracy and clarity of the model.
**Misuse or Lack of Sub-Processes**
Another common mistake is failing to use sub-processes effectively to
simplify and structure your model. Sensible grouping of related activities into
sub-processes not only declutters your diagram but also helps cater to
different audiences—those who prefer high-level overviews, those interested
in detailed steps, and even those focusing on technical specifics.
Without proper use of sub-processes, models become overwhelming and
difficult to navigate, limiting their effectiveness.
Fg 2. 9 The tangling kitten


###### Get Ready With Process-bility

It’s clear that mastering the notation alone isn’t enough. A model might follow
BPMN rules but still fail to communicate effectively. Rather than just focusing on
the technical aspects of BPMN, Process-bility transforms BPMN into a
communication tool that bridges the gap between complex processes and clear
understanding.
At its core, Process-bility is built on three guiding principles:
**_Visual Balance_**
Visual Balance ensures the model is easy on the eyes and easy on the mind.
Proper alignment of elements, consistent spacing, and clear organisation
help the reader grasp the process at a glance. It’s not just about aesthetics—
it’s about making the process model engaging and digestible.


**_Simplicity_**
Simplicity doesn’t mean leaving out important details. It means showing just
enough information to tell the story without overwhelming the reader. In
Process-bility, we focus on “Less is more.” We avoid unnecessary notations and
only include elements that help tell the story. These principles are designed to
ensure that your BPMN models are not just technically accurate, but easy to
understand and impactful for all stakeholders.
**_Storytelling_**
Every process model tells a story - with a beginning, middle, and end. The goal of
BPMN is to ensure that this story is told clearly so everyone can understand it. In
Process-bility, we focus on ensuring the process flow is easy to follow and that
each task, event, and decision fits within a coherent narrative.
Simplicity
is the
ultimate Sophistication
LEONARDO DA VINCI


###### Closing Thoughts

Understanding the foundations of BPMN is crucial, but it’s just the beginning.
Once you grasp the basic elements of BPMN—Activities, Events, Gateways,
Swimlanes, and Connecting Flows—you’re ready to take the next step:
transforming your models into clear, engaging, and visually balanced stories.
Process-bility is here to guide you through that transformation. In the next
chapters, we’ll dive deeper into each of these elements, explore common pitfalls,
and show you how to apply Process-bility principles to make BPMN models that
are both easy to create and easy to understand.
With Process-bility, you’ll not only create better models but also help your team
and stakeholders understand the process more effectively.

#### There is a science in

#### the art of business

#### process modeling.


```
Are you ready for the Gateway?
Exclusive Branching Gateway
Exclusive Merging Gateway
Parallel Branching Gateway
Parallel Merging Gateway
Inclusive Branching Gateway
Inclusive Merging Gateway
Event-Based Gateway
Closing Thoughts
```
### Gateways With Process-bility

##### Chapter 3


###### Are you ready for the Gateway?

Gateways are one of the most misunderstood elements in BPMN. While they are
essential for both controlling the flow and merging multiple paths in a process,
their purpose is often confused, leading to overly complex or inaccurate models.
In Process-bility, we aim to simplify the use of gateways, ensuring they serve
their dual purpose effectively—whether it's routing the flow based on decisions
made elsewhere or merging incoming flows depending on the gateway type.
In this chapter, we’ll explore four key types of gateways:
**Exclusive Gateway** ,
**Parallel Gateway** ,
**Inclusive Gateway** and
**Event-based Gateway**.
Through clear explanations
and analogies, we’ll help you
understand how to use
each one effectively.
Fg 3. 1 The Gateway Heros


###### Exclusive Branching Gateway

The Exclusive Branching Gateway (also known as the XOR Gateway) is the most
commonly used Gateways in BPMN model. Its role is to route the flow of the
process to one of several possible paths based on a decision that has already
been made. Despite its simplicity, the Exclusive Gateway is often misused or
misunderstood.
**What It Does:**
Routes the flow based on decisions made in prior task(s) or activitiy(s).
Chooses only one path to continue the process. In the example, the Exclusive
Branching Gateway - _Min. requirement met_ will route the flow to _Activity C_ if the
_Min. requirement_ was met, it will route the flow to _Activity D_ if the _Min. requirement_
was not met, based on the decision made in either _Activity A_ or _Activity B._
The decision of whether min.
requirement met was made in either
Activity A or B
The gateway routes the correct path
based on the decision that has been
made prior to the gateway
Fg3.2 BPMN Exclusive Branching sample


**What It Doesn’t Do:**
The Exclusive Gateway does not make decisions—this is a common
misconception. The decision is always made in the task or activity prior to the
gateway. The gateway simply routes the flow based on that decision.
**_The Toilet Signage Analogy_**
Think of the Exclusive Branching Gateway like the signage outside public
restrooms—one for men, one for women, and others. The decision of whether to
enter the male or female restroom isn’t made by the signage itself; that decision
was already determined by the person before they approached the restroom. The
signage simply directs you to the appropriate restroom based on a decision made
long before you arrived at that point.
This is exactly how the Exclusive Gateway
operates. The decision has already been
made in the task or activity before the
gateway, and the gateway is simply there
to route the process flow to the correct
path—just like restroom signage directing
you to the right door based on what you
already decided.
Fg 3. 3 Exclusive Gateway Analogy


###### Exclusive Merging Gateway

The Exclusive Merging Gateway routes two or more incoming flows into a single
outgoing flow. It typically reflects an earlier decision made by an Exclusive
Branching Gateway (XOR gateway), where one of several possible paths was
selected based on specific conditions.
**When to Use an Exclusive Merging Gateway** :
Converging Paths: When there are multiple possible branches in a process
(e.g., paths that result from an exclusive branching decision), and you want to
bring them back together into a single flow.
Simplifying Flow Control: If you have different tasks or processes that lead to
the same final step, the exclusive merging gateway can be used to ensure
that the process continues through a single path, regardless of which of the
multiple paths was taken previously.
Fg3.4 BPMN Exclusive Merging sample


**Exclusive Merging Gateway is not recommended in Process-bility**
The exclusive merging gateway is **not recommended** because it tends to add
unnecessary complexity to process models without offering significant clarity.
Here are the key reasons why it is discouraged:
**Redundant Notation** : The Exclusive Merging Gateway is often used when
there are multiple incoming flows, with the intent of merging them back
into a single path. However, this is something that can naturally occur
without the need for an explicit merging gateway. BPMN models allow for
multiple incoming flows to merge without the need for a merging gateway,
making the gateway redundant in most cases.
**Visual Clutter** : Adding gateways where they aren’t needed contributes to
visual clutter. Since Process-bility emphasises simplicity and Visual Balance,
including unnecessary gateways detracts from the model’s clarity and
makes it harder for stakeholders to understand the process at a glance.
**Misleading Representation** : Using an Exclusive Merging Gateway might
imply that a decision is being made at that point, which is not the case. The
decision should have already been made earlier in the process (before the
exclusive branching gateway), and the merging gateway is simply
consolidating the paths. Without proper understanding, this can confuse
readers into thinking there is an additional decision happening at the
merge.


**Encouraging Simplicity** : Process-bility advocates for the **“less is more”**
approach. Instead of overloading the model with gateways for every merging
point, simply connecting the flows without an explicit merging gateway
simplifies the model and maintains the narrative clarity.
By avoiding Exclusive Merging Gateways, Process-bility encourages streamlined,
easy-to-understand models that enhance communication rather than complicate
it.
Fg3.5 BPMN Exclusive Merging - not recommended by Process-bility.


###### Parallel Branching Gateway

The Parallel Branching Gateway is used to manage activities that can occur
simultaneously. It doesn’t evaluate conditions or make decisions but simply
activates multiple branches of a flow.
When the process flow reaches a parallel Branching gateway, all outgoing flows
are triggered at once. This means several tasks can begin simultaneously,
allowing different parts of the process to progress in parallel.
Minimum 2 out flows
As many out flows as per the
business scenario - e.g. 3
Fg3.6 BPMN Parallel Branching Gateway - Sample with two outflows
Fg3.7 BPMN Parallel Branching Gateway - Sample with three outflows


**Dispelling the Myths of Simultaneous Execution of Parallel Gateway**
The Parallel Gateway is often misunderstood as forcing all activities to be
**executed simultaneously**. This **is a misconception**. In reality, the Parallel
Branching Gateway splits the flow into multiple branches that can run in
parallel, but they don’t have to happen at the same time. The gateway simply
allows for multiple tasks to be active at the same time, without imposing any
strict concurrency rules.
For example, imagine a hiring process where, after a candidate is shortlisted,
two activities are initiated in parallel: conducting background checks and
scheduling an interview. While both activities are triggered simultaneously, they
don’t necessarily happen at the exact same time. The background check might
take days, while the interview could be scheduled for the following week. The
Parallel Gateway enables these activities to proceed independently but doesn’t
require them to occur simultaneously. It merely ensures that both tasks must
be completed before the process can continue to the next stage, such as
making a job offer.
Fg3.8 BPMN Parallel Branching Gateway - Sample with two parallel activities


```
Both B and C must be
completed before
proceeding to D
Merging
Merging
```
###### Parallel Merging Gateway

When used to merge flows, the Parallel Merging Gateway ensures that all
incoming paths are completed before proceeding to the next activity. This
guarantees that all parallel activities are finished before the process continues,
keeping everything aligned and coordinated.
B, C & D must be
completed before
proceeding to E
Branching
Branching
Fg3.9 BPMN Parallel Branching and Merging Gateway - Sample with two parallel activities
Fg3.10 BPMN Parallel Branching and Merging Gateway - Sample with three parallel activities


In a job application process, the concept of a Parallel Gateway can be used to
represent activities that happen concurrently. However, in real life, there isn’t
an actual "parallel gateway" ensuring everything happens simultaneously or in
sync.
For example, consider a job application process where, after an applicant
submits their resume, two parallel activities happen:
1. **HR reviews the resume.**

2. **The hiring manager schedules an interview.**
Both activities can occur in parallel, meaning that the HR team and the hiring
manager don’t need to wait for one activity to finish before starting the other.
However, they don’t need to happen at the exact same time—HR might take
longer to review the resume, while the hiring manager might schedule the
interview immediately.
    Fg3.11 BPMN Parallel Branching and Merging Gateway - Sample with two parallel
    activities to illustrate the activities don’t need to happen at the exact same time


**Merging the Parallel Flows** :
Once both activities ( Review Resume and Schedule Job Interview) are
completed, the process moves to the next step, which could be **deciding
whether to extend an offer**. This is represented by a Parallel Gateway,
ensuring that both activities are finished before moving forward.
The Parallel Gateway visually represents this waiting or alignment of activities,
but in practice, it’s the people or systems that ensure all activities are finished
before advancing.
**Human Control** : A recruiter or HR coordinator might manually check that
both the resume review and interview scheduling are done before
advancing to the next step. They act as the "gatekeeper," ensuring all
activities are completed.
**System Control** : In an automated process, an HR system could track the
completion of both activities. The system would wait for confirmation that
both the resume review and interview scheduling are complete before
allowing the process to move to the next step, such as sending an offer
letter or arranging the interview.
Fg3.12 BPMN Parallel Branching and Merging Gateway - Sample with two parallel activities to illustrate
all activities must be first completed before moving to the activity after the Parallel merging gateway


###### Inclusive Branching Gateway

An Inclusive Branching Gateway is used to model situations where one or more
branches may be activated based on the conditions defined in a process. Unlike
the Exclusive Branching Gateway, which allows only one path to be taken, or
the Parallel Branching Gateway, which activates all paths, the Inclusive
Branching Gateway offers flexibility by allowing any combination of branches to
be executed.
An Inclusive Branching Gateway evaluates conditions and then activates one or
more paths based on the results of those conditions.
Minimum 2 out flows
As many out flows as per the
business scenario - e.g. 3
Fg3.13 BPMN Inclusive Branching Gateway - Sample with two outflows
Fg3.14 BPMN Inclusive Branching Gateway - Sample with three outflows


**Inclusive Branching Gateway Example in a Job Application Process:**
Imagine a job application process where, after an initial interview, several
parallel evaluations must occur, but not all are required for every candidate.
1. **Technical Test** : If the candidate is applying for a technical role, they must
take a technical test.
2. **Portfolio Review** : If the candidate is applying for a creative role, their
portfolio must be reviewed.
3. **Background Check** : All candidates, regardless of the role, must undergo a
background check.
Using an Inclusive Branching Gateway allows the process to flow based on
specific conditions. For example:
If the candidate is applying for a technical position, both the **technical test**
and **background check** will be triggered.
If the candidate is applying for a creative role, the **portfolio review** and
**background check** will be activated.
For non-technical, non-creative roles, only the **background check** is performed.
Fg3.15 BPMN Inclusive Branching Gateway - Sample with possible three activities of combinations
Condition 1
Condition 2
Condition 3


###### Inclusive Merging Gateway:

Once the required activities (e.g., technical test, background check, portfolio
review) are completed, the **Inclusive Merging Gateway** is used to bring the
process back into a single flow. This could lead to the final interview step or the
decision to extend an offer.
**Inclusive Merging Gateway Explained** :
The Inclusive Merging Gateway waits for all activated incoming flows to be
completed before proceeding to the next task. This is key to its function—it
doesn’t require all potential incoming flows to be completed, only those that
were activated based on the conditions defined earlier in the process. For
example, if only the **background check** and **technical test** were triggered for
a candidate, the process will wait for just those two activities to be completed
before moving forward. This ensures flexibility while still maintaining control
over the flow of the process.
Branching
Merging
Fg3.16 BPMN Inclusive Branching and Merging Gateway - Sample showing how they work together
Condition 1
Condition 2
Condition 3


###### Event-Based Gateway

An Event-Based Gateway is used to model scenarios where the process flow is
determined by waiting for one of several possible events. These events can be
external or triggered by activities within the process model. Unlike the Exclusive
or Inclusive Gateway, where decisions are based on predefined conditions, the
Event-Based Gateway waits for the occurrence of one of several events before
proceeding along the appropriate path.
**_The Traffic Light Analogy_** **for Event-Based Gateway:**
Imagine you're driving toward a busy intersection with multiple traffic lights.
The path you take depends entirely on which light changes first. You don't
control the lights, but you react based on what happens:
If the light turns green, you move forward (triggering one path).
If a pedestrian crossing signal activates, you wait (triggering another path).
If the emergency vehicle light flashes, you pull over (triggering a different
path).
Just like in Event-Based Gateway, you're simply
waiting for one of several events to occur
before determining your next action.
The gateway directs the flow of the process
based on the event that happens first.
Fg3.17 BPMN Event-
based Gateway analogy


**Scenario: Job Application Process using Event-Based Gateway for
Multiple Response Paths**
In this scenario, after the **Recruitment Team schedules a job interview** , the
process waits for different potential outcomes that dictate the next step. Here’s
how it could unfold using an Event-Based Gateway:
**Candidate confirms the interview** (external event).
**No response from the candidate within 5 days** (external event).
**HR Director suspends the recruitment process** (internal event).
Fg3.18 BPMN Event-based Gateway common usage sample


Each of these events triggers a different path in the process:
If the candidate confirms, the process **proceeds to preparing for the
interview**.
If there is no response within 5 days, the process might **notify the
recruitment team to follow up or take further action.**
If the HR Director suspends the process, all recruitment activities halt, and
the team moves to another task or **reassesses the job position.**
This showcases how the Event-Based Gateway adapts the flow based on
various business events, allowing flexibility in handling different real-world
outcomes that arise during a recruitment process.
Fg3.19 BPMN Event-based Gateway common usage sample for Job application process


After an Event-Based Gateway, only certain types of **Intermediate Catching
Events** can be used. These events typically represent waiting for a specific
signal or occurrence before proceeding in the process.
Here are the possible event types:
These events represent different "triggers" that can occur and determine which
path the process takes after an Event-Based Gateway.

1. **Message Intermediate Catch Event**
    Incoming message (e.g., receiving a document, a request, or a
    notification).
    Example: Candidate confirm the job interview.
2. **Timer Intermediate Event**
    Waits for a specific time to elapse or a deadline to be reached.
    Example: If the candidate doesn't respond within 5 days, this
    timer event is triggered.
3. **Signal Intermediate Catch Event**
    Waits for a broadcast signal that can be triggered by another
    process or activity within the organisation.
    Example: A signal broadcast when a candidate passes a
    background check, which triggers the next step in the process.
4. **Conditional Intermediate Event**
    Waits for a condition to be true before proceeding.
    Example: The process waits for the condition that all necessary
    approvals are completed.


###### Closing Thoughts

Many people misunderstand Gateways, believing they are responsible for
making decisions. In reality, a Gateway is merely a routing mechanism—it does
not decide, but rather directs the flow based on conditions that have already
been determined before reaching the Gateway.
Think of a Gateway like a traffic intersection. The decision to stop, go, or turn is
made by the driver (the process logic), while the traffic lights and road signs (the
Gateway) simply enforce the correct route based on that decision. The same
applies to BPMN: Gateways do not decide; they simply route the process based
on predefined conditions.
Some modelers avoid Gateways altogether, while others overuse them, creating
unnecessary complexity. The goal is balance—use Gateways only when they add
clarity. Too many Gateways can make a process hard to follow; too few can lead
to hidden logic buried inside tasks or flow conditions.
We will explore in Chapter 6&7, on how Process-bility ensures the effective use
of Gateways — keeping models clean, intuitive, and free from unnecessary
complexity while maintaining clear process logic.
Fg 3. 20 Gateway with Process-bility


**What do BPM experts say about Process-bility?**
When people say they don’t understand your perfectly correct
process modes, don’t blame the people. Look to the models.
What business problem do they help to define and resolve?
None, if the target audience doesn’t understand the models.
Read this book. Take Kevin’s advice. Create process models that
communicate.
**Mirko Kloppenburg**
Founder of
NewProcessLab.com
**Hamburg, Germany
Roger Tregear**
Principal Advisor - TregearBPM
**Australia**
Kevin is a true master of this art. — The van Gogh of
business process modelling. And with Process-bility, he
has distilled the fundamentals of his art into a
framework that will help you create your own
masterpieces that will truly inspire people and push your
process forward.
**Roland Woldt**
Process Management & Mining,
Transformation | Podcast Host | Author
**Washington DC, USA**
For over 15 years, the standard for process modeling has been the BPMN
notation. In reality, however, the technical nature of the notation has led us to
create “interesting models” that are not only complex but also confusing.
Kevin’s book shows how can we apply the notation in a way that not only
avoids losing the reader of a diagram but also creates clarity and minimizes
room for misinterpretation. This places “BPMN Made Easy with Process-bility”
a step above the typical BPMN books that merely explain the specification or
how to use a BPMN-supporting tool.


**What do BPM experts say about Process-bility?**
My journey through training and coaching process modelers has revealed the complexities inherent in
BPMN. These experiences prompted Kevin to refine his approach, ultimately culminating in the creation of
BPMN Made Easy with Process-bility. Influential voices in this field, like Bruce Silver, have divided the
BPMN palette into manageable layers, providing clarity through his influential work, BPMN Method and
Style. Kevin Tan has further simplified this approach by emphasizing three guiding principles: Storytelling,
Visual Balance, and Simplicity.
As the statistician George E. P. Box aptly noted, “All models are wrong, but some are useful.” By embracing
Process-bility, you will be equipped to create models that are not only useful but also comprehensible,
enabling your organization to implement and continually improve its processes. This book serves as a
beacon for anyone seeking to harness the true power of BPMN and elevate their business practices to new
heights. Welcome to a journey of clarity, innovation, and meaningful transformation.
**Clyde Livingston**
Senior Manager | Business Process
Management (BPM)
**Sydney, Australia**
An exceptional guide that demystifies Business Process Model and
Notation (BPMN) for both newcomers and seasoned practitioners.
His engaging narrative style transforms BPMN from a complex topic
into an intuitive approach, enabling readers to confidently visualize
and enhance workflows. This book is a valuable asset for anyone
aiming to improve their process modeling expertise and boost
organizational efficiency.
**Gerald G**
BPM Lecturer at Ateneo de Manila University
**Manila, Philippines**


In a landscape where clarity in business process modelling is paramount yet often elusive, Kevin Tan’s
BPMN Made Easy with Process-bility stands out as a significant advancement in the use of the BPMN
methodology. As an advocate for Universal Process Notation (UPN), I’ve often emphasized simplicity,
consistency, and actionable insights in process maps—values that are mirrored in Kevin’s novel approach
to BPMN. His concept of “Process-bility” distills BPMN’s complexities into accessible, meaningful
narratives that can engage everyone from executive leaders to frontline teams.
Kevin’s three guiding principles—Storytelling, Visual Balance, and Simplicity—serve not only as a model
for BPMN but as a reminder of what process modeling should achieve: intuitive communication that
drives understanding and action. These principles align with the UPN framework, particularly the
emphasis on answering fundamental questions of What, Why, When, Who, and How in every process
step. Kevin’s focus on why processes matter to a business exemplifies this alignment, as he encourages
modelers to avoid excessive technical detail in favour of transparent, purpose-driven flow.
Through Process-bility, I believe Kevin has crafted a guide that is both thorough and accessible, bridging
the often challenging gap between technical rigor and business relevance. His approach offers clarity in
depicting complex processes, avoiding BPMN’s common pitfalls of over-detailing and misused gateways
by advocating just the right amount of notation, the right narrative flow, and the right visual organization.
This dedication to clarity makes BPMN Made Easy with Process-bility a valuable resource for anyone
addressing a wider audience, not just experienced analysts or technical experts.
Kevin’s work is not just about refining a tool; it’s about reshaping how we communicate and collaborate
through process models. As you journey through his insightful chapters, you’ll find practical techniques
that transform BPMN from a technical exercise into an essential language of shared understanding, a
principle I believe will bring enduring value to organizations of all sizes.
**Walter Th. Bril**
Co-inventor and UPN Advocate
**Maastricht, The Netherlands
What do BPM experts say about Process-bility?**


Kevin book is great for organisations, process leadership, and practitioners that
have invested in the concept of process and want to get it right. In these pages
he translates his extensive experience and his thought leadership on this topic
into practical tips for creating process models that convey a story that can be
used by a broad range of stakeholders for many transformational use cases.
This is a must read for anyone that wants to not just create process models but
ensure that these models make a lasting positive impact for their organisation.
**Michael Schank**
Digital Transformation &
Operational Excellence
Consultant
**USA
What do BPM Authors say about Process-bility?**
An amazing, engaging, beautiful book. Many books discuss
process modelling using BPMN, but very few references deliver
on their promise. Those that do often fail to strike the delicate
balance between content and form and add further complexity
to an already complex subject matter.
“BPMN Made Easy with Process-bility by Kevin Tan, from
complexity to clarity” lives up to its promise
If you are a business process analyst struggling with BPMN, this
book by a distinguished expert in the field is for you.
Engaging, informative and practical.
A must-have book for serious learners and practitioners.
**Ali Darwish**
Author, BPM Expert, Educator and Mentor
**Melbourne, Australia**


It's a game changer, I must say, having lately had the honour of being among the
first readers of this amazing guide! This book is for everyone who has ever felt
overpowered by the intricacies of BPMN.
Kevin Tan's Process-bility method eliminates ambiguity and prioritizes
storytelling, clarity, and simplicity. Instead of becoming bogged down in
technical details, Process-bility concentrates on developing models that are
visually balanced, understandable, and genuinely captivating. The goal is to
transform process diagrams into comprehensible, captivating stories that inspire
teams to take action.
**Denys Ignatius**
Business Analyst
**Wellington, New Zealand
What do Readers say about Process-bility?**
BPMN Made Easy with Process-bility is
exactly what the BPMN world needed:
A guide that finally speaks human.
**Patrick Nguyen**
Business Process Designer
**Berlin, Germany**
This certainly is one of the best books ever written on BPMN. Highly
recommended.
Kevin Tan's book, BPMN Made Easy With Process-bility, is an absolute
masterpiece that transforms the often convoluted world of Business
Process Model and Notation (BPMN) into a straightforward and engaging
experience. This book serves as an invaluable resource for both
newcomers and seasoned professionals eager to deepen their
understanding of business processes
**Partha Mohapatra**
IT Business Analyst
**Melbourne, Australia**


**Rizwan Khaliq**
Business Process Analyst
**Birmingham, England, United Kingdom
What do Readers say about Process-bility?**
It simplifies process mapping like no other book. It cuts
through unnecessary complexity, focusing on visual
clarity and storytelling to make BPMN easy to understand
and apply.
BPMN is nothing that comes easily out of the hand. You have to learn how
to apply the rules and suddenly you own a technically wonderful work of
process modelling.
In order to inspire employees, to awaken in them the desire for clarity in
the processes, we can forget "technically wonderful".
Acceptance and interest in the application only arises through intuitive use
with visibly meaningful results. Kevin Tan shows that this can be done
without breaking the rules but putting people at the centre.
Thank you for this book! It's a real treasure.
**Katrin Wetzel**
Head of Business Process Management
**Westfalen, Germany**
Kevin simplifies process, if you’re new to process modelling
or want to learn,
look no further this is the book for you.
Kevin is a process expert , this book is a must read, you will
thank me later.
Anne Alessandro
Process Improvement Specialist
Melbourne, Australia


I’ve read many posts by Kevin Tan about Process-bility or heard him speak
in podcasts over the past few years. I’ve always been impressed by his
approach to making processes simple and easy to understand.
This book helped me grasp his approach even more deeply. The concept of
visual balance, in particular, became much more tangible and
comprehensible for me. I’m looking forward to gradually applying this
knowledge in my own work.
An absolutely recommended book for anyone involved in processes or
process modeling: clear, practical, and inspiring!
**Cynthia Agughalam**
Business Analyst
**Canada
What do Readers say about Process-bility?**
It is truly transformational. It removes the complexity from
BPMN and presents it in a clear, understandable, and
practical way. As a reader, I was guided on a journey—from
grasping the fundamentals to becoming a more confident
and effective modeler with each chapter. For the first time,
I'm finally seeing the true value of BPMN, beyond the
confusing and complex concept it once was for me
**Daniel Kempa**
LEARNFLUENCER
**Germany
Lina Druskiene**
Business Analyst
**Vilniaus, Lithuania**
Thank you Kevin for writing the eye
opening BPMN book we didn’t know we
needed — and now can’t live without.


**What do Readers say about Process-bility?**
Kevin, thanks for bringing
BPMN back down to earth
— where it belongs.
**Urszula Tokarska**
Process Excellence Lead
**Poland**
One of the best gifts you
can give yourself is a
copy of this book. It’s a
game-changer.
**Yemi Oke**
RPA Business Analyst
**Preston, England**


I'm proud to have been part of a project that has the
potential to revolutionise the way people approach
process mapping. Process-bility is a testament to
Kevin's expertise and dedication to helping others.
As a product designer and enter-training enthusiast,
Kevin's approach of transforming heavy technical
information into accessible, enjoyable learning
experiences truly resonated with me.
As a fellow business analyst professional, I'm excited
to have this handy reference to guide my work.
**Note from the illustrator:**
Click here to open the video
_If you're curious about how I
used AI to illustrate for this book,
check out my YouTube video. I'll
also discuss the challenges and
opportunities that AI image
generators present for non-
creatives looking to enhance
their posts or products._
**Orsi Palfi**
linkedin.com/in/orsipalfi/
**Australia**


**Thank you for reading Chapters 1-3 of BPMN Made Easy with Process-bility!**
I am grateful that you found these chapters useful and insightful. This glimpse is
just the beginning of a transformative approach to BPMN through Storytelling,
Visual Balance, and Simplicity. The full Book will offer even more comprehensive
insights, advanced techniques, and practical examples to help you become a
true BPMN master.
If you're ready to dive deeper and unlock the complete guide, I invite you to
place your order for the Book today.
Don't miss out on the opportunity to enrich your BPMN skills and transform
your approach to process modeling.
The paperback version is available at
[http://www.process-bility.com](http://www.process-bility.com) ( special discount )
Amazon.com
The eBook is available at [http://www.process-bility.com](http://www.process-bility.com)
Thank you for being part of the Process-bility journey!
Warm regards,
**Kevin Tan**


