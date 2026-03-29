import axios, { AxiosError, InternalAxiosRequestConfig, AxiosHeaders } from 'axios';
import Cookies from 'js-cookie';

const timeout = 30000;

export interface AppAxiosConfig {
  headers: AxiosHeaders;
}

interface RetryableRequest extends InternalAxiosRequestConfig {
  _retry?: boolean;
}

export const appAxios = (config?: AppAxiosConfig) => {
  const defaultAppAxiosConfigs = {
    timeout,
  };

  const axiosInstance = config
    ? axios.create(config)
    : axios.create(defaultAppAxiosConfigs);

  axiosInstance.interceptors.request.use(
    (configParam) => configParam,
    (error) => Promise.reject(error)
  );

  axiosInstance.interceptors.response.use(
    (response) => response,
    async (error: AxiosError) => {
      const originalRequest = error.config as RetryableRequest;

      if (
        error.response?.status === 401 &&
        (error.response?.data as { message?: string })?.message === 'token expired' &&
        !originalRequest?._retry
      ) {
        try {
          originalRequest._retry = true;

          await new Promise((resolve) => setTimeout(resolve, 1000));

          const newToken = Cookies.get('ksectoken');

          if (originalRequest.headers instanceof AxiosHeaders) {
            originalRequest.headers.set('token', newToken);
          } else {
            const headers = new AxiosHeaders(originalRequest.headers);
            headers.set('token', newToken);
            originalRequest.headers = headers;
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