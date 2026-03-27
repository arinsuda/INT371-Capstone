import axios, { AxiosError, InternalAxiosRequestConfig, AxiosHeaders } from 'axios';
import getConfig from 'next/config';
import Cookies from 'js-cookie';

// const { publicRuntimeConfig } = getConfig();
const timeout =  30000;

export interface AppAxiosConfig {
  headers: AxiosHeaders;
}


// เพิ่ม interface สำหรับ extend InternalAxiosRequestConfig
interface RetryableRequest extends InternalAxiosRequestConfig {
  _retry?: boolean;
}

export const appAxios = (config?: AppAxiosConfig) => {
  const defaultAppAxiosConfigs = {
    timeout: Number.parseInt(`${timeout}`),
  };
  const axiosInstance = config ? axios.create(config) : axios.create(defaultAppAxiosConfigs);

  axiosInstance.interceptors.request.use(
    (configParam) => {
      return configParam;
    },
    (error) => {
      return Promise.reject(error);
    }
  );

  axiosInstance.interceptors.response.use(
    (response) => {
      return response;
    },
    async (error: AxiosError) => {
      const originalRequest = error.config as RetryableRequest;
      
      if ((error.response?.status === 401) && 
          (error.response?.data as { message?: string })?.message === 'token expired' &&
          !originalRequest?._retry) {
            try {
              originalRequest._retry = true;
              
              await new Promise(resolve => setTimeout(resolve, 1000));
              
              const newToken = Cookies.get('ksectoken');
              
              if (originalRequest.headers instanceof AxiosHeaders) {
                originalRequest.headers.set('token', newToken);
              } else {
                const headers = new AxiosHeaders(originalRequest.headers);
                headers.set('token', newToken);
                originalRequest.headers = headers;
              }
              
              if (originalRequest.data) {
                originalRequest.data = originalRequest.data;
              }
              
              return axiosInstance(originalRequest);
            } catch (refreshError) {
              return Promise.reject(refreshError);
            }
      }
      return Promise.reject(error);
    }
  );

  return axiosInstance;
};