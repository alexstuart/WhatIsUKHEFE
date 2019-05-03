# WhatIsUKHEFE

The rules of Jisc's May 2019 Edtech challenge say: You must be a registered student on a course at a university or college in the UK. Colloquially, this has been refered to as ".ac.uk". The exact definition of what is UK HE and FE will depend on the application.

Recognising the complexity of the definition and the power of iteration, this script provides a first approximation to answering the question, and provides the ability to add or remove individual IdPs to tailor the community to fit your needs.

The default algorithm takes a metadata aggregate (typically the UK federation's production aggregate) and lists visible IdPs which are registered by the UK federation and which have one or more scopes that end with .ac.uk

