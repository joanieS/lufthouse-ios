Lufthouse README
Updated 8/14/14
Copyright (c) 2014 Lufthouse. All rights reserved.

**Concerning the JSON**

We start by defining the relation between the JSON, the customer, and a tour. The JSON contains all customer
records and the tours that belong to each customer. In that, we state that the JSON has many customers, and
a customer has many tours.

This relationship is broken up into two segments which the app processes at two different points:

Segment one contains a list of each nearby customer and their respective tours. The structure resembles the following:

    [
        {
            name : "Customer name",
            id : 123456,
            installations: [
                { active: BOOL,
                  name: "Tour name",
                  id: 111,
                  image_url: http://www.pathto.com/myimage.png
                },
                { active: BOOL,
                  name: "Other tour name",
                  id: 222,
                  image_url: http://www.pathto.com/myimage.png
                }
            ]
        },
        {
            name : "Other customer name",
            id : 456789,
            installations: [
                { active: BOOL,
                  name: "Tour name",
                  id: 111,
                  image_url: http://www.pathto.com/myimage.png
                },
                { active: BOOL,
                  name: "Other tour name",
                  id: 222,
                  image_url: http://www.pathto.com/myimage.png
                }
            ]
        }
    ]

This example contains all of the fields needed for loading the customer and tour selection pages.


The second segment loads the details of the tour in a separate JSON. It should resemble the following:

    {
        name: "Name of the tour",
        beacons: [
            {
                minor_id: 12345,
                content: "Content depending on content-type; see below",
                content_type: "see-below",
                audio_url: "http://www.yourpathto.com/audio.mp3",
                id: 123
            },
            {
                minor_id: 98765,
                content: "Content depending on content-type; see below",
                content_type: "see-below",
                audio_url: "http://www.yourpathto.com/audio.mp3",
                id: 456
            }
        ]
    }

*Concerning Audio*

When including audio, place the name of the file with extension into the audio part of the entry. If you
wish to not include audio, the CMS should return a null object, translating into a NSNull class object in
Objective C.

Examples:

    audio_url: "http://www.audiopath.com/bestsongever.mp3",
    audio_url: null,

*Concerning Content and Content Types*

The following content types are availble in the app:

"web" - This is a basic webpage. Using the URL to said webpage, add the following to the JSON:

    content: "http://www.awesomewebsite.com",
    content_type: "web",
    
"image" - This is a local or online image. Local images are only accessible if the file is bundled with the app. Otherwise, a url will work and is preferred.

    content: "http://www.awesomewebsite.com/awesomerimage.png",
    content_type: "image",
    
"web-video" - This is an online video for YouTube. It is displayed in an embedded video player. It cannot
    autoplay, and takes the id section from the YouTube URL (e.x. "12345Z" from www.youtube.com/watch?v=12345Z):

    content: "556cf88379d",
    content_type: "web-video",

"photo-gallery" - Swipeable gallery of local and online images. Structure as such:

    content: ["http://www.awesomewebsite.com/kitteh.png", "http://www.awesomewebsite.com/doggeh.png"],
    content_type: "photo-gallery",

"record-audio" - Recordable section for "I remember when" feature. Only needs a content type:

    content_type: "record-audio",
    
"memories" - Displayable section for "I remember when" feature. Needs a content type as well as an array of URLs to the memories.

    content: ["http://www.awesomewebsite.com/memory1.caf", "http://www.awesomewebsite.com/memory2.caf"],
    content_type: "memories",
