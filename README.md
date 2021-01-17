# Github Page for BennyHoward

Source code for Github Pages [bennyhoward.github.io](https://bennyhoward.github.io).  

## Author

- [Benny Howard](mailto:bennyhoward.opensource@gmail.com)

## Contributing

*No contributions will be accepted in this repository.*  

## License

![Creative Commons License](./by-sa.svg)  
This work is licensed under a <a rel="license" href="http://creativecommons.org/licenses/by-sa/4.0/">Creative Commons Attribution-ShareAlike 4.0 International License</a>.  

## How to Setup repo for Github Pages and Prepare it for a Domain Name

### 1. 

## Deploying

The contents of the dist folder is what gets deployed.  

The deployment script, [deploy.sh](./deploy.sh) will run the deployment.  
This deployment script will overwrite the [LICENSE](./LICENSE) file in the `dist` folder every time.  

**DO NOT** forget to also include to add the [LICENSE](./LICENSE) file in the `dist` folder for the deployment branch `gh-pages`.  

To deploy run the following command:  

```sh
sh ./deploy.sh
```
