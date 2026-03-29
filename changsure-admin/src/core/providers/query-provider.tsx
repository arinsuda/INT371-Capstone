"use client";
import { AxiosError } from "axios";
import React, { useState } from "react";
import {
  QueryClient,
  QueryCache,
  QueryClientProvider,
} from "@tanstack/react-query";

export const QueryProviderLayout = (props: {
  children: React.ReactElement;
}) => {
  //---------------------
  //   CONST
  //---------------------
  const [queryClient] = useState(
    () =>
      new QueryClient({
        queryCache: new QueryCache({
onError: (error) => {
  const axiosError = error as AxiosError<{ message?: string }>;

  console.log(
    axiosError.response?.data?.message || axiosError.message
  );
},
        }),
        defaultOptions: {
          queries: {
            refetchOnWindowFocus: false,
          },
        },
      })
  );

  //---------------------
  //   RENDER
  //---------------------
  return (
    <QueryClientProvider client={queryClient}>
      {props.children}
    </QueryClientProvider>
  );
};
