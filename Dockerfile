FROM mcr.microsoft.com/dotnet/core/sdk:2.2 AS publish
WORKDIR /src
COPY ./DotNetFlicks.Accessors ./DotNetFlicks.Accessors
COPY ./DotNetFlicks.Common ./DotNetFlicks.Common
COPY ./DotNetFlicks.Engines ./DotNetFlicks.Engines
COPY ./DotNetFlicks.Managers ./DotNetFlicks.Managers
COPY ./DotNetFlicks.ViewModels ./DotNetFlicks.ViewModels
COPY ./DotNetFlicks.Web ./DotNetFlicks.Web
COPY ./DotNetFlicks.sln ./DotNetFlicks.sln

#Add in the contrast sensors
RUN dotnet add  "DotNetFlicks.Web/Web.csproj" package Contrast.SensorsNetCore --package-directory ./contrast 

#Compile the app
RUN dotnet publish "DotNetFlicks.Web/Web.csproj" /p:Platform=x64 -c Release -o /app

FROM mcr.microsoft.com/dotnet/core/aspnet:2.2 AS final
RUN uname -a
RUN apt-get update && apt-get --assume-yes install libnss3-tools
WORKDIR /app
EXPOSE 80
COPY --from=publish /app .

#Copy the yaml configuration
ADD /contrast_security.yaml ./contrast_security.yaml

#Set the enrivonment vars to enable the agent
ENV CORECLR_PROFILER_PATH_64 ./contrast/runtimes/linux-x64/native/ContrastProfiler.so
ENV CORECLR_PROFILER {8B2CE134-0948-48CA-A4B2-80DDAD9F5791}
ENV CORECLR_ENABLE_PROFILING 1
ENV CONTRAST_CONFIG_PATH ./contrast_security.yaml
ENV CONTRAST__APPLICATION__NAME netflicks
ENV CONTRAST__SERVER__NAME aks
ENV ASPNETCORE_ENVIRONMENT QA
ENV CONTRAST_CORECLR_LOGS_DIRECTORY /opt/contrast/

ENTRYPOINT ["dotnet", "DotNetFlicks.Web.dll"]
