## 5corelife mobile project

Project based on react native. It is based on reactjs version 17, gradle version 6.4, compiled for andoird as IOs. The steps of how it is composed are a little detailed:

To see the current versions and possible updates of the libs, take into account the following command

```npm outdated```

1. Replace "@react-native-community/asyncstorage" with the new version "@react-native-async-storage/async-storage, to see the documentation go to the following link https://www.npmjs.com/package /@react-native-async-storage/async-storage?activeTab=readme

When modifying async storage, all packages associated with the community lib must be modified to the new one. Be careful when running on IOS because the Podfile.lock file has the old version


2. Keep in mind that when it is executed, it must connect to the 5corelife backend, for this the docker-compose must be executed, and to connect to it from the front end locally, you must go to the path "5corelife/src /helpers/api" and add the URL constant with the IP 10.0.2.2 to the port where the backend is running.

```export const URL = 'http://10.0.2.2:8000/'```

To test if we are reaching the backend from the emulator, go to the emulator, open a chrome tab and enter the following path "http://10.0.2.2:8000/api" if the django admin responds, we are successfully reaching the backend backend. Currently already configured, but to take into account future applications.

4. Once the above has been corrected, install with npm

```npm install```

5. After installing, we generate the apk for android, executing the command

```npm run android```

6. If we have problems with the compilation, we delete the cache of metro and our andorid and IOs, to do this we execute the following:

metro cache:

```watchman watch-from '$HOME/5corelife'```

```watchman watch-project '$HOME/5corelife'```

Command for android, found in package.json

```npm run android:clean```

Command for IOs

```npm run ios:clean```

7. If you have problem with IOs, you can use the following commands. You need to be in "ios/" folder path to run the commands

Command to deintegrate the Pod

```pod deintegrate```

Command to install

```pod install```

Command to check the dependeincies valids the latest version

```pod outdated```

Command to update dependencies

```pod update```

youc can specify the package too

```pod update Firebase```

Very important, you need to comment in Podfiles the package with the set version, and run the previos command to update the last version.

