---
title: "What is Augmented Reality?"
date: 2023-02-10 12:00
parent: [tutorials]
---
Augmented Reality is a technology that enhances a user's perception of the real world by overlaying digital assets in their view of the physical environment.

## Why should developers learn about Augmented Reality (AR)?

To create a deeper immersion in the narrative that your product delivers, some experiences might be more impactful
when 3D objects interacting with the world around us.

## AR core components.

- **Display device** (could be a smartphone or dedicated Augmented, Mixed Reality headset) - processes digital information coming from the tracking system and 3D-enabled applications for the user. This can be either a transparent lens that allows the user to see the real world with digital objects, or a screen which blocks a user's direct view of the real world but captures real world via camera and displays digital elements, in real-time, in the semi-virtual environment.

- **Tracking system** - determines the position and orientation of the device in the real world. This can be done using sensors such as invisible laser beams, cameras, accelerometers, and gyroscopes. The tracking system uses this information to align the digital assets with the user's view of the real world, so that it appears to be at the correct distance and orientation.

- **Experience (AKA Software)** - responsible for displaying the digital assets (3D models, animations, music, images, videos and text) and aligning it with the real world. This software can be a standalone app or a browser-based system that uses web technologies to deliver the AR content.

## How does AR work?

For Augmented Reality to work, the device has to know its 3D position in the world. In order to do so, an algorithm called *SLAM* ("Simultaneous Localization and Mapping") has to go through the process of creating a digital representation of the physical world in real-time.

**Simultaneous Localization and Mapping (SLAM)** is the process of creating a map of the environment while simultaneously determining the location of the device within that environment.  The goal of *SLAM* is to create a highly accurate map of the environment that can be used to overlay digital assets in the correct location and orientation. It fuses data from multiple sensors and estimate the device's position and orientation. SLAM also uses a technique called loop closure to detect when the device has returned to a previously visited location, and to correct for any accumulated errors in the map. Running *SLAM* algorithms can be computationally intensive and require significant processing power.

There are two main types of *SLAMs*:

- **Marker-based SLAM** - uses specific visual patterns, known as markers, to identify a specific location or object in the real-world environment. When the device's camera recognizes the marker, it can then accurately overlay the digital assets on that object or within the space around it.

- **Markerless SLAM** - uses the information from the Tracking System to track the position and orientation of the device in the real-world environment.


## LiDAR (Light Detection and Ranging or "laser imaging, detection, and ranging")

LiDAR is a technology that uses **laser beams** to measure distances to objects and create detailed 3D maps of the surrounding environment. In *Augmented Reality (AR)*, *LiDAR* can be used to do multiple things, such as:

- Improving the accuracy and realism of virtual objects by assigning correct position and orientation in relation to real-world objects and surfaces.
- Enabling features such as *Occlusion*, where virtual objects are hidden behind real-world objects, and collision detection, where virtual
objects interact realistically with real-world objects. 

    This works by emitting laser beams (lol) and measuring the time it takes for them to bounce back from objects in the environment. This information is used to calculate the distance to the objects and create a 3D point cloud of the environment.
- Creating detailed maps of the environment(in AR), which can then be used to accurately place virtual objects.

    For example, if a virtual chair is placed in an AR application, *LiDAR* can be used to ensure that it is placed on the floor rather than floating in mid-air.


## Shaders

*Shaders* are used in a variety of applications, including video games, 3D animation, augmented and virtual reality experiences. They allow developers to create more realistic and immersive visuals by adding features such as lighting, shadows, reflections, and more. For example, using *Shaders*, developers can create reflections and refractions, which can make water behave realistically, or special effects, such as explosions and particles, which can enhance 3D experiences. In a nutshell *Shaders* are small programs predominantly written in C that utilize the graphic processing unit (GPU) of a device.

There are different types of *Shaders*: **Vertex Shaders** and **Fragment Shaders**, each of which performs a specific
function:

- A **Vertex shader** is a graphics processing function used which adds special effects to objects in a 3D environment by performing mathematical operations on the objects' vertex data [(source:nvidia)](https://www.nvidia.com/en-us/drivers/feature-vertexshader/#:~:text=A%20vertex%20shader%20is%20a,defined%20by%20many%20different%20variables.)

- A **Fragment Shader** determines the final colour of each pixel on the screen. Here is an example of basic [three.js](https://threejs.org/) gradient fragment shader (.glsl)

    ![](assets/image001.png)  

			varying vec2 vUvs;
			void main () {
			gl_FragColor = mix(
			vec4(vUvs.x, vUvs.x, 10, 1.0),
			vec4(vUvs.y, vUvs.x, 1.0, 1.0),
			vUvs.y
			);

## Occlusion

*Occlusion* is a concept that refers to the ability of real-world objects to block or obscure virtual objects. This can be used to create more realistic and immersive experiences by making the virtual objects in a scene behave as if they are interacting with the real world.

## AR development frameworks

There are several key frameworks and SDKs (software development kits) available for developing *Augmented Reality (AR)* applications.

- [ARKit](https://developer.apple.com/documentation/arkit), developed by Apple for iOS devices. **ARKit** provides a set of tools for developers to create AR experiences for iPhone and iPad, using the device's camera, processor and motion sensors. The framework includes tools like [**Reality Composer**](https://apps.apple.com/us/app/reality-composer/id1462358802) (WYSIWYG AR Scene Prototyping and Production), [Reality Converter](https://developer.apple.com/news/?id=01132020a) (Helps with converting 3D files .obj, .gltf to .[usd](https://graphics.pixar.com/usd/release/spec_usdz.html)), **[Universal Scene Description (USD)](https://developer.apple.com/documentation/arkit/usdz_schemas_for_ar)**, a comprehensive 3D content format, and [RealityKit](https://developer.apple.com/documentation/realitykit) and [SceneKit](https://developer.apple.com/documentation/scenekit/), the main renderers for **ARKit** based AR experiences. **ARKit** also offers features like [Occlusion ](https://developer.apple.com/documentation/arkit/camera_lighting_and_effects/occluding_virtual_content_with_people)and [Motion Capture](https://developer.apple.com/documentation/arkit/content_anchors/capturing_body_motion_in_3d).
- [ARCore ](https://developers.google.com/ar/develop/fundamentals) is Google's AR framework for Android devices. Like **ARKit**, it provides a set of tools for developers to create AR experiences on Android OS.

- Web-based AR frameworks - [8th Wall](https://www.8thwall.com/) offers one main advantage over SDKs: to allow developers to create AR experiences that can be accessed and used on a wide range of devices through a URL without the need to download and install a separate app. This makes it much easier for users to access and experience the AR content, increasing its reach and potential audience. It also offers features like *image tracking*, *real-time shadows* and *occlusion*. It can be developed using popular web technologies such as JavaScript([aframe.js](https://aframe.io/), [three.js](https://threejs.org/) and [webGL](https://developer.mozilla.org/en-US/docs/Web/API/WebGL_API))

## AR use cases

AR technology has the potential to bring significant business value in various industries.

- **Healthcare:** by providing new and innovative ways to diagnose and treat patients, train healthcare professionals, and improve the
    overall patient experience. AR can be used to train healthcare professionals, such as medical students and nurses. By overlaying digital information, 3D models with animations and simulating more realistic and interactive learning experience, AR can allow healthcare professionals to gain better understand of anatomy and various procedures. AR also can add a lot of value in planning for surgical procedures by transforming patient's data and images into 3D models of their internal body structures. This can help surgeons to plan and perform procedures more accurately and safely, reducing the risk of complications and improving the outcome for patients. In the field of rehabilitation, AR can be used to provide patients with more engaging and interactive rehabilitation experiences. Rehabilitation exercises can be made more challenging and fun by allowing patients to interact with virtual objects, which in turn may improve the patients' adherence to the treatment plan.

    - [Combining Computer Vision and Augmented Reality](https://blogs.oracle.com/research/post/pneumonia-ai-combining-computer-vision-augmented-reality)

- **Gaming** - AR games allow players to experience a game in the real world. Players can interact with virtual characters and objects as if they were real, leading to an immersive and engaging experience. For example, Pokémon Go is a widely popular game that uses AR technology for players to catch virtual Pokemon in real world locations.
    - [Extreme Pokémon GO player](https://www.youtube.com/watch?v=Dzo7zcNtAbM&ab_channel=TheStar)
    - [TOP 100 Pokémon GO Tips and Tricks!](https://www.youtube.com/watch?v=mfnZDPw6w8Y&ab_channel=MYSTIC7)

- **Field** - works with education to provide maintenance and repair instructions for complex equipment. Users can overlay digital twin information on the physical equipment, providing them with step-by-step instructions on how to repair or maintain it. In manufacturing it can help guide workers through the assembly process, ensuring that they have the right tools and parts in the right order to complete the task.

- **Remote assistance** - simultaneously render digital twin data in multiple geographic locations giving subject matter experts insights into performance of the device and so then can assist field technician in troubleshooting process.
    - [Remote assistance demo](https://youtu.be/nqmLEiwnCfY)

- **Interior design** - AR allows users to see what furniture and decor would look like in their home before making a purchase. With AR, users can visualize the furniture in their space, making it easy to see how different pieces will look and fit.

- **Retail** - Virtual Try-On's allow users to visualize clothes, shoes, and jewelry virtually. Impacting both return rates for
    items that don't fit and sales by delivering better experience. [(Source: Snap Consumer AR Global - Deloitte)](https://www2.deloitte.com/content/dam/Deloitte/xe/Documents/About-Deloitte/Snap%20Consumer%20AR_Global%20Report_2021.pdf)

- **Tourism** - AR can provide information about historical landmarks, buildings, and other points of interest. Tourists can use AR to navigate and get directions or build a deeper understanding and connection to the history and culture of the place they are visiting.

## Key requirements for AR backend infrastructure

- [API Management](https://www.oracle.com/uk/cloud/cloud-native/api-management/) - An API management solution is needed to handle the communication between the AR application and the back-end servers services to offload hardware overload. An API management solution should be able to handle a large number of ingress and egress calls which can vary based on the requirements.

- [Storage](https://www.oracle.com/uk/cloud/storage/) and [Content Management](https://www.oracle.com/uk/content-management/) - The back-end infrastructure must be able to manage and store large amounts of data, such as 3D models, scenes, images, audio and other digital assets used in the AR experience. The overall strategy of managing asset lifecycle should be considered when making selection of the storage platform.

- [Scalability](https://blogs.oracle.com/developers/post/autoscaling-your-workload-on-oracle-cloud-infrastructure) - The back-end infrastructure must be able to handle a large number of structured [RDBMS](https://www.oracle.com/uk/database/) and unstructured data -- [learn more about data types here](https://www.oracle.com/big-data/structured-vs-unstructured-data/).

- [Security](https://www.oracle.com/uk/security/cloud-security/) - The back-end infrastructure must be able to secure and protect sensitive data, digital twins, and assets. This requires a secure data storage and processing system that can prevent unauthorized access, data breaches, and other security threats.

## Potential adoption challenges

One of the key challenges in AR technology is accurately aligning the digital assets with the real-world environment, known as registration. The registration process should be as seamless and accurate as possible to create a believable and awesome experience for the user.

- **Current hardware and software** - Mobile devices, such as smartphones and tablets, are often not powerful enough to handle the computational demands of sophisticated AR applications. Dedicated AR devices, such as headsets, are still not widely available. Additionally, many current AR applications require specialized hardware, such as depth-sensing cameras, which are not yet widely available on most devices.

- **Limited field of view (FOV)** - Most devices have a relatively small FOV, which can limit the sense of immersion and realism in the AR experience. Some wearable devices have a larger FOV, but they are still not as wide as the human FOV, which is around 180 degrees. This is an important factor to take into account when creating an AR experience, as it can significantly impact the user's perception of the virtual and real-world environments.

- **Complexity** - the software development lifecycle coupled with lengthy process of creating 3D models. Integration of computer vision techniques, such as marker-based and markerless tracking, depth sensing and environment mapping, often add to the complexity of the development process.

- **User's safety** - specifically, when the user is interacting with both virtual and real-world environments -- this could lead to accidents if the user's attention is completely absorbed by the AR experience.

Get started with 3D on Oracle:

- [Digital Twin and healthcare on OCI ](https://www.youtube.com/watch?v=Ot-vBMEch1o&ab_channel=PaulXR%28PaulParkinsonatOracle%29)
- [Deploy Unreal Engine on Oracle Linux](<https://developer.oracle.com/tutorials/vdi-on-oci>)
- [Deploy Metaverse room on OCI](<https://medium.com/oracledevs/40th-anniversary-tron-day-metaverse-room-on-oci-fb24a3200fc7>)
